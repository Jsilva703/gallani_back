class ServiceSerializer
  def initialize(service)
    @service = service
  end

  def as_json(*)
    {
      id: @service.id,
      name: @service.name,
      description: @service.description,
      price: @service.price.to_f,
      active: @service.active
    }
  end
end
