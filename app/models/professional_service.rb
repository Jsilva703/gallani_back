class ProfessionalService < ApplicationRecord
  belongs_to :professional
  belongs_to :service

  validates :service_id, uniqueness: { scope: :professional_id }
end
