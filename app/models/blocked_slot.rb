class BlockedSlot < ApplicationRecord
  belongs_to :professional

  validates :date, presence: true
  validate :does_not_overlap_existing_block

  private

  def does_not_overlap_existing_block
    return if professional.blank? || date.blank?

    scope = professional.blocked_slots.where(date: date)
    scope = scope.where.not(id: id) if persisted?

    conflict = if time.nil?
                 scope.exists?
               else
                 scope.where(time: nil).or(scope.where(time: time)).exists?
               end

    errors.add(:time, "conflita com bloqueio existente") if conflict
  end
end
