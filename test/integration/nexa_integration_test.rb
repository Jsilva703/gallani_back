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

    AvailabilitySlot.create!(
      professional: @professional,
      weekday: @date.wday,
      time: "10:00"
    )

    _record, raw = ApiToken.generate!(label: "nexa-test")
    @headers = {
      "Authorization" => "Bearer #{raw}",
      "Content-Type" => "application/json"
    }
  end

  test "consulta disponibilidade e cria agendamento" do
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
             time: "10:00"
           }
         }.to_json,
         headers: @headers

    assert_response :created

    get "/api/v1/integrations/nexa/availability",
        params: {
          professional_id: @professional.id,
          date: @date.iso8601
        },
        headers: @headers

    assert_response :success
    assert_empty JSON.parse(response.body).fetch("times")
  end
end
