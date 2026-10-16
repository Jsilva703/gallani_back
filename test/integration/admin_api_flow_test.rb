require "test_helper"
require "securerandom"

class AdminApiFlowTest < ActionDispatch::IntegrationTest
  setup do
    password = SecureRandom.hex(16)
    admin = User.create!(
      name: "Admin",
      email: "admin@example.com",
      password: password,
      password_confirmation: password,
      role: "admin"
    )
    _session, raw = UserSession.issue_for!(admin)

    @headers = {
      "Authorization" => "Bearer #{raw}",
      "Content-Type" => "application/json"
    }
  end

  test "fluxo administrativo cria serviço profissional cliente e agendamento" do
    post "/api/v1/admin/services",
         params: {
           service: {
             name: "Corte",
             description: "Corte masculino",
             price: 50
           }
         }.to_json,
         headers: @headers

    assert_response :created
    service_id = JSON.parse(response.body).dig("data", "id")

    post "/api/v1/admin/professionals",
         params: {
           professional: {
             name: "Moisés",
             phone: "11999999999",
             service_ids: [service_id]
           }
         }.to_json,
         headers: @headers

    assert_response :created
    professional_id = JSON.parse(response.body).dig("data", "id")

    date = Date.current + 1.day

    post "/api/v1/admin/availability_slots",
         params: {
           availability_slot: {
             professional_id: professional_id,
             weekday: date.wday,
             time: "10:00"
           }
         }.to_json,
         headers: @headers

    assert_response :created

    post "/api/v1/admin/customers",
         params: {
           customer: {
             name: "Cliente",
             phone: "11988887777",
             email: "cliente@example.com"
           }
         }.to_json,
         headers: @headers

    assert_response :created
    customer_id = JSON.parse(response.body).dig("data", "id")

    post "/api/v1/admin/appointments",
         params: {
           appointment: {
             customer_id: customer_id,
             professional_id: professional_id,
             service_id: service_id,
             date: date.iso8601,
             time: "10:00"
           }
         }.to_json,
         headers: @headers

    assert_response :created
    appointment_id = JSON.parse(response.body).dig("data", "id")

    patch "/api/v1/admin/appointments/#{appointment_id}/status",
          params: { status: "confirmed" }.to_json,
          headers: @headers

    assert_response :success

    assert_difference("FinancialEntry.count", 1) do
      patch "/api/v1/admin/appointments/#{appointment_id}/status",
            params: {
              status: "completed",
              payment_method: "pix"
            }.to_json,
            headers: @headers
    end

    assert_response :success
    assert_equal "completed", JSON.parse(response.body).dig("data", "status")

    assert_no_difference("FinancialEntry.count") do
      patch "/api/v1/admin/appointments/#{appointment_id}/status",
            params: { status: "completed" }.to_json,
            headers: @headers
    end

    assert_response :success
  end

  test "token de integração não acessa admin" do
    _record, raw = ApiToken.generate!(label: "test-integration")

    get "/api/v1/admin/services",
        headers: { "Authorization" => "Bearer #{raw}" }

    assert_response :unauthorized
  end
end
