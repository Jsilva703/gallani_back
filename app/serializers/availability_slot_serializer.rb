class AvailabilitySlotSerializer
  def initialize(slot)
    @slot = slot
  end

  def as_json(*)
    {
      id: @slot.id,
      professional_id: @slot.professional_id,
      weekday: @slot.weekday,
      time: @slot.time.strftime("%H:%M"),
      active: @slot.active
    }
  end
end
