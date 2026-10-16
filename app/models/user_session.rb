require "digest"
require "securerandom"

class UserSession < ApplicationRecord
  DEFAULT_TTL = 30.days
  LAST_USED_WRITE_INTERVAL = 15.minutes

  belongs_to :user

  validates :token_digest, :expires_at, presence: true
  validates :token_digest, uniqueness: true

  scope :valid_now, -> { where("expires_at > ?", Time.current) }

  def self.issue_for!(user, ttl: DEFAULT_TTL)
    raw_token = SecureRandom.hex(32)

    session = create!(
      user: user,
      token_digest: digest(raw_token),
      expires_at: Time.current + ttl
    )

    [session, raw_token]
  end

  def self.authenticate(raw_token)
    return if raw_token.blank?

    session = valid_now.includes(user: :professional).find_by(token_digest: digest(raw_token))
    return unless session&.user&.access_allowed?

    session
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def mark_used!
    return if last_used_at && last_used_at > LAST_USED_WRITE_INTERVAL.ago

    update_column(:last_used_at, Time.current)
  end
end
