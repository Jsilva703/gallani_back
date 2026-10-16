class AppointmentStatusService
  class InvalidTransition < StandardError; end
  class PaymentMethodRequired < StandardError; end

  TRANSITIONS = {
    "scheduled" => %w[confirmed cancelled no_show],
    "confirmed" => %w[completed cancelled no_show],
    "completed" => [],
    "cancelled" => [],
    "no_show" => []
  }.freeze

  def initialize(appointment:, target_status:, payment_method: nil)
    @appointment = appointment
    @target_status = target_status.to_s
    @payment_method = payment_method
  end

  def call
    entry = nil

    Appointment.transaction do
      @appointment.lock!

      if @appointment.status == @target_status
        entry = @appointment.financial_entry if @target_status == "completed"
        next
      end

      allowed = TRANSITIONS.fetch(@appointment.status, [])
      raise InvalidTransition, "transição de status inválida" unless allowed.include?(@target_status)

      if @target_status == "completed" && @payment_method.blank?
        raise PaymentMethodRequired, "payment_method é obrigatório"
      end

      @appointment.update!(status: @target_status)

      entry = create_financial_entry! if @target_status == "completed"
    end

    [@appointment, entry]
  end

  private

  def create_financial_entry!
    @appointment.financial_entry || FinancialEntry.create!(
      entry_type: "income",
      description: "Atendimento - #{@appointment.service.name}",
      appointment: @appointment,
      customer: @appointment.customer,
      professional: @appointment.professional,
      service: @appointment.service,
      payment_method: @payment_method,
      amount: @appointment.price,
      date: @appointment.date
    )
  end
end
