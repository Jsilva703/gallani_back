class AppointmentSerializer
  def initialize(appointment, include_relations: false)
    @appointment = appointment
    @include_relations = include_relations
  end

  def as_json(*)
    data = {
      id: @appointment.id,
      customer_id: @appointment.customer_id,
      professional_id: @appointment.professional_id,
      service_id: @appointment.service_id,
      date: @appointment.date.iso8601,
      time: @appointment.formatted_time,
      price: @appointment.price.to_f,
      status: @appointment.status
    }

    if @include_relations
      data[:customer] = {
        id: @appointment.customer.id,
        name: @appointment.customer.name,
        phone: @appointment.customer.phone
      }
      data[:professional] = {
        id: @appointment.professional.id,
        name: @appointment.professional.name
      }
      data[:service] = {
        id: @appointment.service.id,
        name: @appointment.service.name
      }
    end

    data
  end
end
