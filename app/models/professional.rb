class Professional < ApplicationRecord
  has_one :user, dependent: :restrict_with_error

  has_many :professional_services, dependent: :destroy
  has_many :services, through: :professional_services
  has_many :availability_slots, dependent: :destroy
  has_many :availability_exceptions, dependent: :destroy
  has_many :blocked_slots, dependent: :destroy
  has_many :appointments, dependent: :restrict_with_error
  has_many :financial_entries, dependent: :nullify

  validates :name, presence: true
  before_validation :normalize_phone
  validates :phone, presence: true, uniqueness: true

  private

  def normalize_phone
    normalized_phone = phone.to_s.gsub(/\D/, "")

    if normalized_phone.length.in?([10, 11])
      self.phone = normalized_phone
    else
      errors.add(:phone, "deve ser um número de telefone válido com 10 ou 11 dígitos")
    end
  end
end
