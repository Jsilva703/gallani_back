class Service < ApplicationRecord
  has_many :professional_services, dependent: :destroy
  has_many :professionals, through: :professional_services
  has_many :appointments, dependent: :restrict_with_error
  has_many :financial_entries, dependent: :nullify

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
