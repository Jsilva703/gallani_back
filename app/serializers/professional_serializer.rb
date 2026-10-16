class ProfessionalSerializer
  def initialize(professional, include_services: false)
    @professional = professional
    @include_services = include_services
  end

  def as_json(*)
    data = {
      id: @professional.id,
      name: @professional.name,
      phone: @professional.phone,
      active: @professional.active,
      service_ids: @professional.service_ids
    }

    if @include_services
      data[:services] = @professional.services.map { |service| ServiceSerializer.new(service).as_json }
    end

    data
  end
end
