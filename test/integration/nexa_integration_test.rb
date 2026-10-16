require "test_helper"

class NexaIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @service = Service.create!(
      name: "Corte",
      description: "Corte masculino",
      price: 50
    )

    @professional = Professional.create!(
      name: "Moisés",
      phone: "11999999999"
    )
    @professional.services << @service

    @customer = Customer.create!(
      name: "Cliente",
      phone: "11988887777"
    )

    @date = Date.current + 1.day
    @second_date = Date.current + 2.days

    AvailabilitySlot.create!(
      professional: @professional,
      weekday: @date.wday,
      time: "10:00"
    )

    AvailabilitySlot.create!(
      professional: @professional,
      weekday: @second_date.wday,
      time: "11:00"
    )

    _record, raw = ApiToken.generate!(label: "nexa-test")
    @headers = {
      "Authorization" => "Bearer #{raw}",
      "Content-Type" => "application/json"
    }
  end

  test "consulta profissionais ativos e cliente por telefone" do
    get "/api/v1/integrations/nexa/professionals",
        params: { service_id: @service.id },
        headers: @headers

    assert_response :success
    assert_equal @professional.id, JSON.parse(response.body).dig("data", 0, "id")

    get "/api/v1/integrations/nexa/customers",
        params: { phone: "(11) 98888-7777" },
        headers: @headers

    assert_response :success
    assert_equal @customer.id, JSON.parse(response.body).dig("data", 0, "id")
  end

  test "consulta disponibilidade cria lista remarca e cancela agendamento" do
    get "/api/v1/integrations/nexa/availability",
        params: {
          professional_id: @professional.id,
          date: @date.iso8601
        },
        headers: @headers

    assert_response :success
    assert_equal ["10:00"], JSON.parse(response.body).fetch("times")

    post "/api/v1/integrations/nexa/appointments",
         params: {
           appointment: {
             customer_id: @customer.id,
             professional_id: @professional.id,
             service_id: @service.id,
             date: @date.iso8601,
             time: "10:00",
             price: 1
           }
         }.to_json,
         headers: @headers

    assert_response :created
    appointment = JSON.parse(response.body).fetch("data")
    appointment_id = appointment.fetch("id")
    assert_equal 50.0, appointment.fetch("price")

    get "/api/v1/integrations/nexa/appointments",
        params: { customer_id: @customer.id },
        headers: @headers

    assert_response :success
    result = JSON.parse(response.body).fetch("data")
    assert_equal [appointment_id], result.map { |item| item.fetch("id") }

    patch "/api/v1/integrations/nexa/appointments/#{appointment_id}/reschedule",
          params: {
            date: @second_date.iso8601,
            time: "11:00"
          }.to_json,
          headers: @headers

    assert_response :success
    assert_equal @second_date.iso8601, JSON.parse(response.body).dig("data", "date")
    assert_equal "11:00", JSON.parse(response.body).dig("data", "time")

    patch "/api/v1/integrations/nexa/appointments/#{appointment_id}/cancel",
          headers: @headers

    assert_response :success
    assert_equal "cancelled", JSON.parse(response.body).dig("data", "status")

    get "/api/v1/integrations/nexa/appointments",
        params: { customer_id: @customer.id },
        headers: @headers

    assert_response :success
    assert_empty JSON.parse(response.body).fetch("data")
  end
end


class NexaIntegrationFilteringTest < ActionDispatch::IntegrationTest
  setup do
    @service = Service.create!(
      name: "Serviço ativo",
      description: "Ativo",
      price: 40
    )
    @inactive_service = Service.create!(
      name: "Serviço inativo",
      description: "Inativo",
      price: 30,
      active: false
    )
    @professional = Professional.create!(
      name: "Profissional ativo",
      phone: "11912345678"
    )
    @professional.services << [@service, @inactive_service]

    _record, raw = ApiToken.generate!(label: "nexa-filter-test")
    @headers = { "Authorization" => "Bearer #{raw}" }
  end

  test "não lista profissional para serviço inativo" do
    get "/api/v1/integrations/nexa/professionals",
        params: { service_id: @inactive_service.id },
        headers: @headers

    assert_response :success
    assert_empty JSON.parse(response.body).fetch("data")
  end

  test "rejeita telefone inválido na busca de cliente" do
    get "/api/v1/integrations/nexa/customers",
        params: { phone: "123" },
        headers: @headers

    assert_response :unprocessable_entity
    assert_equal "telefone deve conter 10 ou 11 dígitos", JSON.parse(response.body).fetch("error")
  end
end
