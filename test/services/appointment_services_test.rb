require "test_helper"

class AppointmentServicesTest < ActiveSupport::TestCase
  setup do
    @service = Service.create!(
      name: "Corte",
      description: "Corte masculino",
      price: 50
    )
    @professional = Professional.create!(
      name: "Profissional",
      phone: "11922221111"
    )
    @professional.services << @service
    @customer = Customer.create!(
      name: "Cliente",
      phone: "11911112222"
    )
    @date = Date.current + 1.day

    AvailabilitySlot.create!(
      professional: @professional,
      weekday: @date.wday,
      time: "10:00"
    )

    AvailabilitySlot.create!(
      professional: @professional,
      weekday: (@date + 1.day).wday,
      time: "11:00"
    )
  end

  test "criação sempre congela o preço atual do serviço" do
    appointment = AppointmentCreationService.new(
      attributes: {
        customer_id: @customer.id,
        professional_id: @professional.id,
        service_id: @service.id,
        date: @date,
        time: "10:00",
        price: 1
      }
    ).call

    assert_equal @service.price, appointment.price
  end

  test "remarca agendamento ativo e volta para scheduled" do
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

    new_date = @date + 1.day
    AppointmentRescheduleService.new(
      appointment: appointment,
      date: new_date.iso8601,
      time: "11:00"
    ).call

    assert_equal new_date, appointment.reload.date
    assert_equal "11:00", appointment.formatted_time
    assert_equal "scheduled", appointment.status
  end

  test "não reabre histórico terminal por remarcação" do
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
      target_status: "cancelled"
    ).call

    assert_raises(AppointmentRescheduleService::InvalidStatus) do
      AppointmentRescheduleService.new(
        appointment: appointment,
        date: (@date + 1.day).iso8601,
        time: "11:00"
      ).call
    end

    assert_equal "cancelled", appointment.reload.status
    assert_equal @date, appointment.date
  end
end
