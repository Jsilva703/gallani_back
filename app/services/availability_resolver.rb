class AvailabilityResolver
  def initialize(professional:, date:)
    @professional = professional
    @date = date
  end

  def configured_times
    exception = @professional.availability_exceptions.find_by(date: @date)
    return exception.times.sort if exception

    @professional.availability_slots
                 .where(weekday: @date.wday, active: true)
                 .order(:time)
                 .map { |slot| slot.time.strftime("%H:%M") }
  end
end
