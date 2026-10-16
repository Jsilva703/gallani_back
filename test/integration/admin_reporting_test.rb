require "test_helper"
require "securerandom"

class AdminReportingTest < ActionDispatch::IntegrationTest
  setup do
    password = SecureRandom.hex(16)
    admin = User.create!(
      name: "Admin",
      email: "reporting-admin@example.com",
      password: password,
      password_confirmation: password,
      role: "admin"
    )
    _session, raw = UserSession.issue_for!(admin)

    @headers = {
      "Authorization" => "Bearer #{raw}",
      "Content-Type" => "application/json"
    }

    @service = Service.create!(
      name: "Corte",
      description: "Corte masculino",
      price: 50
    )
    @professional = Professional.create!(
      name: "Profissional",
      phone: "11955554444"
    )
    @professional.services << @service
    @customer = Customer.create!(
      name: "Cliente Principal",
      phone: "11944443333",
      email: "principal@example.com"
    )
    @date = Date.current

    AvailabilitySlot.create!(
      professional: @professional,
      weekday: @date.wday,
      time: "10:00"
    )

    appointment = AppointmentCreationService.new(
      attributes: {
        customer_id: @customer.id,
        professional_id: @professional.id,
        service_id: @service.id,
        date: @date,
        time: "10:00"
      }
    ).call

    AppointmentStatusService.new(
      appointment: appointment,
      target_status: "confirmed"
    ).call

    AppointmentStatusService.new(
      appointment: appointment,
      target_status: "completed",
      payment_method: "pix"
    ).call

    FinancialEntry.create!(
      entry_type: "expense",
      description: "Material",
      category: "products",
      amount: 20,
      date: @date
    )
  end

  test "caixa retorna relações resumo e ticket médio" do
    get "/api/v1/admin/financial_entries",
        params: {
          start_date: @date.iso8601,
          end_date: @date.iso8601,
          per_page: 5
        },
        headers: @headers

    assert_response :success

    payload = JSON.parse(response.body)
    income = payload.fetch("data").find { |entry| entry.fetch("type") == "income" }

    assert_equal @customer.name, income.dig("customer", "name")
    assert_equal @professional.name, income.dig("professional", "name")
    assert_equal @service.name, income.dig("service", "name")
    assert_equal 50.0, payload.dig("summary", "income")
    assert_equal 20.0, payload.dig("summary", "expense")
    assert_equal 30.0, payload.dig("summary", "balance")
    assert_equal 50.0, payload.dig("summary", "average_ticket")
    assert_equal 5, payload.dig("meta", "per_page")
  end

  test "busca administrativa de cliente filtra nome e telefone" do
    Customer.create!(
      name: "Outro Cliente",
      phone: "11933332222",
      email: "outro@example.com"
    )

    get "/api/v1/admin/customers",
        params: { query: "Principal" },
        headers: @headers

    assert_response :success
    result = JSON.parse(response.body).fetch("data")
    assert_equal [@customer.id], result.map { |customer| customer.fetch("id") }

    get "/api/v1/admin/customers",
        params: { query: "944443333" },
        headers: @headers

    assert_response :success
    assert_equal @customer.id, JSON.parse(response.body).dig("data", 0, "id")
  end

  test "bloqueios aceitam filtro de intervalo" do
    future_date = @date + 7.days
    BlockedSlot.create!(
      professional: @professional,
      date: future_date,
      reason: "Folga"
    )

    get "/api/v1/admin/blocked_slots",
        params: {
          from: future_date.iso8601,
          to: future_date.iso8601,
          professional_id: @professional.id
        },
        headers: @headers

    assert_response :success
    result = JSON.parse(response.body).fetch("data")
    assert_equal 1, result.size
    assert_equal future_date.iso8601, result.first.fetch("date")
  end
end
