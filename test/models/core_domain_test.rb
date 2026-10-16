require "test_helper"

class CoreDomainTest < ActiveSupport::TestCase
  setup do
    @service = Service.create!(
      name: "Corte",
      description: "Corte masculino",
      price: 50
    )

    @professional = Professional.create!(
      name: "Moisés",
      phone: "(11) 99999-9999"
    )
    @professional.services << @service

    @customer = Customer.create!(
      name: "Cliente",
      phone: "(11) 98888-7777",
      email: "cliente@example.com"
    )

    @date = Date.current + 1.day
    AvailabilitySlot.create!(
      professional: @professional,
      weekday: @date.wday,
      time: "10:00"
    )
  end

  test "normaliza telefone do profissional" do
    assert_equal "11999999999", @professional.phone
  end

  test "agendamento copia preço do serviço" do
    appointment = Appointment.create!(
      customer: @customer,
      professional: @professional,
      service: @service,
      date: @date,
      time: "10:00"
    )

    assert_equal BigDecimal("50.0"), appointment.price
    assert_equal "scheduled", appointment.status
  end

  test "impede dois agendamentos ativos no mesmo horário" do
    Appointment.create!(
      customer: @customer,
      professional: @professional,
      service: @service,
      date: @date,
      time: "10:00"
    )

    second = Appointment.new(
      customer: @customer,
      professional: @professional,
      service: @service,
      date: @date,
      time: "10:00"
    )

    assert_not second.valid?
    assert_includes second.errors[:time], "já possui agendamento"
  end

  test "exceção substitui disponibilidade semanal" do
    AvailabilityException.create!(
      professional: @professional,
      date: @date,
      times: ["14:00"]
    )

    assert_equal ["14:00"], AvailabilityResolver.new(
      professional: @professional,
      date: @date
    ).configured_times
  end

  test "bloqueio de dia inteiro conflita com bloqueio específico existente" do
    BlockedSlot.create!(
      professional: @professional,
      date: @date,
      time: "10:00"
    )

    whole_day = BlockedSlot.new(
      professional: @professional,
      date: @date,
      time: nil
    )

    assert_not whole_day.valid?
  end
end
