class FinancialEntrySerializer
  def initialize(entry)
    @entry = entry
  end

  def as_json(*)
    {
      id: @entry.id,
      type: @entry.entry_type,
      description: @entry.description,
      appointment_id: @entry.appointment_id,
      customer_id: @entry.customer_id,
      professional_id: @entry.professional_id,
      service_id: @entry.service_id,
      customer: relation_payload(@entry.customer),
      professional: relation_payload(@entry.professional),
      service: relation_payload(@entry.service),
      payment_method: @entry.payment_method,
      category: @entry.category,
      amount: @entry.amount.to_f,
      date: @entry.date.iso8601
    }
  end

  private

  def relation_payload(record)
    return unless record

    {
      id: record.id,
      name: record.name
    }
  end
end
