class Customer < ApplicationRecord
  has_many :appointments, dependent: :restrict_with_error
  has_many :financial_entries, dependent: :nullify

  validates :name, presence: true
  validates :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  before_validation :normalize_phone

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
