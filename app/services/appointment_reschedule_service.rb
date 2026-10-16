class AppointmentRescheduleService
  class InvalidStatus < StandardError; end

  RESCHEDULABLE_STATUSES = %w[scheduled confirmed].freeze

  def initialize(appointment:, date:, time:)
    @appointment = appointment
    @date = Date.iso8601(date.to_s)
    @time = time
  end

  def call
    professional = @appointment.professional

    professional.with_lock do
      @appointment.lock!

      unless RESCHEDULABLE_STATUSES.include?(@appointment.status)
        raise InvalidStatus, "agendamento neste status não pode ser remarcado"
      end

      @appointment.update!(
        date: @date,
        time: @time,
        status: "scheduled"
      )
    end

    @appointment
  end
end
