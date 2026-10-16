class AvailabilityException < ApplicationRecord
  TIME_FORMAT = /\A(?:[01]\d|2[0-3]):[0-5]\d\z/

  belongs_to :professional

  validates :date, presence: true
  validates :date, uniqueness: { scope: :professional_id }
  validate :times_are_valid

  before_validation :normalize_times

  private

  def normalize_times
    self.times = Array(times).map(&:to_s).map(&:strip).reject(&:blank?).uniq.sort
  end

  def times_are_valid
    invalid_times = Array(times).reject { |value| value.match?(TIME_FORMAT) }
    errors.add(:times, "contém horário inválido") if invalid_times.any?
  end
end
