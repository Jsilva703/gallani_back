class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: @user.id,
      name: @user.name,
      email: @user.email,
      role: @user.role,
      active: @user.active,
      professional_id: @user.professional_id,
      professional: professional_payload
    }
  end

  private

  def professional_payload
    return unless @user.professional

    {
      id: @user.professional.id,
      name: @user.professional.name,
      active: @user.professional.active
    }
  end
end
