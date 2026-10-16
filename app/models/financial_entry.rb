class FinancialEntry < ApplicationRecord
  ENTRY_TYPES = %w[income expense].freeze
  PAYMENT_METHODS = %w[pix cash debit credit other].freeze
  CATEGORIES = %w[products maintenance rent energy other].freeze

  belongs_to :appointment, optional: true
  belongs_to :customer, optional: true
  belongs_to :professional, optional: true
  belongs_to :service, optional: true

  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :description, :date, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_blank: true
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validate :income_has_payment_method
  validate :expense_has_category

  scope :income, -> { where(entry_type: "income") }
  scope :expense, -> { where(entry_type: "expense") }

  private

  def income_has_payment_method
    return unless entry_type == "income" && payment_method.blank?

    errors.add(:payment_method, "é obrigatório para entrada")
  end

  def expense_has_category
    return unless entry_type == "expense" && category.blank?

    errors.add(:category, "é obrigatória para despesa")
  end
end
