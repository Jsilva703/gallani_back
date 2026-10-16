require "test_helper"
require "securerandom"

class ProfessionalAccessTest < ActionDispatch::IntegrationTest
  setup do
    @service = Service.create!(
      name: "Corte",
      description: "Corte masculino",
      price: 50
    )

    @professional = Professional.create!(
      name: "Profissional",
      phone: "11999990001"
    )
    @professional.services << @service

    @other_professional = Professional.create!(
      name: "Outro profissional",
      phone: "11999990002"
    )
    @other_professional.services << @service

    password = SecureRandom.hex(16)
    @user = User.create!(
      name: "Profissional",
      email: "professional@example.com",
      password: password,
      password_confirmation: password,
      role: "professional",
      professional: @professional
    )

    _session, raw = UserSession.issue_for!(@user)
    @headers = {
      "Authorization" => "Bearer #{raw}",
      "Content-Type" => "application/json"
    }

    @date = Date.current + 1.day
    AvailabilitySlot.create!(
      professional: @professional,
      weekday: @date.wday,
      time: "10:00"
    )
  end

  test "visualiza somente o próprio perfil profissional" do
    get "/api/v1/professional/profile", headers: @headers

    assert_response :success
    payload = JSON.parse(response.body).fetch("data")

    assert_equal @professional.id, payload.dig("professional", "id")
    assert_equal [@service.id], payload.dig("professional", "service_ids")
  end

  test "não acessa namespace administrativo" do
    get "/api/v1/admin/services", headers: @headers
    assert_response :unauthorized
  end

  test "pesquisa e cria cliente" do
    existing = Customer.create!(
      name: "Cliente Existente",
      phone: "11988887777",
      email: "existing@example.com"
    )

    Customer.create!(
      name: "Outro Cliente",
      phone: "11988886666",
      email: "other@example.com"
    )

    get "/api/v1/professional/customers",
        params: { query: "Existente" },
        headers: @headers

    assert_response :success
    result = JSON.parse(response.body).fetch("data")
    assert_equal [existing.id], result.map { |customer| customer.fetch("id") }

    get "/api/v1/professional/customers",
        params: { query: "NaoExiste" },
        headers: @headers

    assert_response :success
    assert_empty JSON.parse(response.body).fetch("data")

    post "/api/v1/professional/customers",
         params: {
           customer: {
             name: "Cliente Novo",
             phone: "11977776666",
             email: "new@example.com"
           }
         }.to_json,
         headers: @headers

    assert_response :created
  end

  test "cria agendamento somente para si mesmo" do
    customer = Customer.create!(
      name: "Cliente",
      phone: "11966665555"
    )

    post "/api/v1/professional/appointments",
         params: {
           appointment: {
             customer_id: customer.id,
             professional_id: @other_professional.id,
             service_id: @service.id,
             date: @date.iso8601,
             time: "10:00"
           }
         }.to_json,
         headers: @headers

    assert_response :created

    appointment = Appointment.order(:id).last
    assert_equal @professional.id, appointment.professional_id
    assert_equal @service.price, appointment.price
  end

  test "profissional desativado perde acesso" do
    @professional.update!(active: false)

    get "/api/v1/professional/profile", headers: @headers

    assert_response :unauthorized
  end
end
