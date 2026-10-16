require "digest"
require "securerandom"

class ApiToken < ApplicationRecord
  SCOPES = %w[integration].freeze
  LAST_USED_WRITE_INTERVAL = 15.minutes

  validates :label, :token_digest, presence: true
  validates :scope, inclusion: { in: SCOPES }
  validates :token_digest, uniqueness: true

  def self.generate!(label:, scope: "integration")
    raw_token = SecureRandom.hex(32)
    record = create!(
      label: label,
      scope: scope,
      token_digest: digest(raw_token)
    )

    [record, raw_token]
  end

  def self.authenticate(raw_token)
    return if raw_token.blank?

    find_by(token_digest: digest(raw_token), active: true)
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def mark_used!
    return if last_used_at && last_used_at > LAST_USED_WRITE_INTERVAL.ago

    update_column(:last_used_at, Time.current)
  end
end
