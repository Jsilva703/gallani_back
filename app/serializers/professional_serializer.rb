class ProfessionalSerializer
  def initialize(professional)
    @professional = professional
  end

  def as_json(*)
    {
      id: @professional.id,
      name: @professional.name,
      phone: @professional.phone,
      active: @professional.active
    }
  end
end