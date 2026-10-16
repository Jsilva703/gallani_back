class User < ApplicationRecord
  ROLES = %w[admin professional].freeze

  belongs_to :professional, optional: true
  has_many :user_sessions, dependent: :destroy

  has_secure_password

  before_validation :normalize_email

  validates :name, :email, :role, presence: true
  validates :email,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :professional_link_matches_role

  scope :active, -> { where(active: true) }

  def access_allowed?
    return false unless active?
    return true unless role == "professional"

    professional&.active? == true
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def professional_link_matches_role
    if role == "professional" && professional.blank?
      errors.add(:professional, "é obrigatório para usuário profissional")
    elsif role == "admin" && professional.present?
      errors.add(:professional, "não deve ser informado para administrador")
    end
  end
end
