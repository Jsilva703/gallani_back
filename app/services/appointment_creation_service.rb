class AppointmentCreationService
  def initialize(attributes:, professional: nil)
    @attributes = attributes.to_h.symbolize_keys
    @professional = professional
  end

  def call
    attributes = @attributes.except(:price)
    professional = @professional || Professional.find_by(id: attributes.delete(:professional_id))
    appointment = Appointment.new(attributes.merge(professional: professional))

    if professional
      professional.with_lock { appointment.save! }
    else
      appointment.save!
    end

    appointment
  end
end
