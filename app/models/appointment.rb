class Appointment < ApplicationRecord
  ACTIVE_STATUSES = %w[scheduled confirmed].freeze

  belongs_to :customer
  belongs_to :professional
  belongs_to :service

  has_one :financial_entry, dependent: :restrict_with_error

  enum :status, {
    scheduled: "scheduled",
    confirmed: "confirmed",
    completed: "completed",
    cancelled: "cancelled",
    no_show: "no_show"
  }

  validates :date, :time, :status, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :professional_is_active, on: :create
  validate :service_is_active, on: :create
  validate :service_is_offered_by_professional, if: :service_assignment_needs_validation?
  validate :slot_is_available, if: :slot_needs_validation?

  before_validation :copy_service_price, if: -> { price.blank? }

  def formatted_time
    time&.strftime("%H:%M")
  end

  private

  def copy_service_price
    self.price = service&.price
  end

  def professional_is_active
    errors.add(:professional, "está inativo") if professional && !professional.active?
  end

  def service_is_active
    errors.add(:service, "está inativo") if service && !service.active?
  end

  def service_assignment_needs_validation?
    new_record? ||
      will_save_change_to_professional_id? ||
      will_save_change_to_service_id?
  end

  def service_is_offered_by_professional
    return if professional.blank? || service.blank?
    return if professional.service_ids.include?(service_id)

    errors.add(:service, "não é realizado por este profissional")
  end

  def slot_needs_validation?
    new_record? ||
      will_save_change_to_date? ||
      will_save_change_to_time? ||
      will_save_change_to_professional_id?
  end

  def slot_is_available
    return if professional.blank? || date.blank? || time.blank?

    time_value = formatted_time
    configured = AvailabilityResolver.new(professional: professional, date: date).configured_times

    unless configured.include?(time_value)
      errors.add(:time, "não está disponível para este profissional")
      return
    end

    blocked = professional.blocked_slots.where(date: date)
                          .where("time IS NULL OR time = ?", time)
                          .exists?

    if blocked
      errors.add(:time, "está bloqueado")
      return
    end

    conflict = professional.appointments
                           .where(date: date, time: time, status: ACTIVE_STATUSES)
    conflict = conflict.where.not(id: id) if persisted?

    errors.add(:time, "já possui agendamento") if conflict.exists?
  end
end
