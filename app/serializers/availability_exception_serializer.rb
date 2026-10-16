class AvailabilityExceptionSerializer
  def initialize(exception)
    @exception = exception
  end

  def as_json(*)
    {
      id: @exception.id,
      professional_id: @exception.professional_id,
      date: @exception.date.iso8601,
      times: @exception.times
    }
  end
end
