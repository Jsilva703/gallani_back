class BlockedSlotSerializer
  def initialize(blocked_slot)
    @blocked_slot = blocked_slot
  end

  def as_json(*)
    {
      id: @blocked_slot.id,
      professional_id: @blocked_slot.professional_id,
      date: @blocked_slot.date.iso8601,
      time: @blocked_slot.time&.strftime("%H:%M"),
      reason: @blocked_slot.reason
    }
  end
end
