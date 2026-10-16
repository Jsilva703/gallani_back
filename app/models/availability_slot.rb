class AvailabilitySlot < ApplicationRecord
  belongs_to :professional

  validates :weekday, inclusion: { in: 0..6 }
  validates :time, presence: true
  validates :time, uniqueness: { scope: %i[professional_id weekday] }
end
