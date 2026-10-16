class AgendaService
  MAX_RANGE_DAYS = 62

  def initialize(from:, to:, professional_id: nil, summary: false)
    @from = Date.iso8601(from.to_s)
    @to = Date.iso8601(to.to_s)
    @professional_id = professional_id
    @summary = ActiveModel::Type::Boolean.new.cast(summary)

    raise ArgumentError, "intervalo inválido" if @to < @from
    raise ArgumentError, "intervalo máximo é de #{MAX_RANGE_DAYS} dias" if (@to - @from).to_i > MAX_RANGE_DAYS
  end

  def call
    load_data
    @summary ? summary_payload : detailed_payload
  end

  private

  def load_data
    @professionals = professional_scope.to_a
    professional_ids = @professionals.map(&:id)

    @weekly_slots = AvailabilitySlot.where(
      professional_id: professional_ids,
      active: true
    ).order(:time).group_by { |slot| [slot.professional_id, slot.weekday] }

    @exceptions = AvailabilityException.where(
      professional_id: professional_ids,
      date: @from..@to
    ).index_by { |exception| [exception.professional_id, exception.date] }

    @blocks = BlockedSlot.where(
      professional_id: professional_ids,
      date: @from..@to
    ).group_by { |block| [block.date, block.professional_id] }

    appointments = Appointment.includes(:customer, :professional, :service)
                              .where(
                                professional_id: professional_ids,
                                date: @from..@to,
                                status: Appointment::ACTIVE_STATUSES
                              )
                              .to_a

    @appointments_by_slot = appointments.group_by do |appointment|
      [appointment.date, appointment.professional_id, appointment.formatted_time]
    end

    @appointment_times = appointments.group_by do |appointment|
      [appointment.date, appointment.professional_id]
    end.transform_values do |items|
      items.map(&:formatted_time).uniq
    end
  end

  def professional_scope
    booked_professional_ids = Appointment.where(
      date: @from..@to,
      status: Appointment::ACTIVE_STATUSES
    ).select(:professional_id)

    scope = Professional.where(active: true)
                        .or(Professional.where(id: booked_professional_ids))
                        .order(:name)

    scope = scope.where(id: @professional_id) if @professional_id.present?
    scope
  end

  def dates
    @dates ||= (@from..@to).to_a
  end

  def configured_times(professional, date)
    return [] unless professional.active?

    exception = @exceptions[[professional.id, date]]
    return exception.times.sort if exception

    Array(@weekly_slots[[professional.id, date.wday]])
      .map { |slot| slot.time.strftime("%H:%M") }
  end

  def booked_times(professional, date)
    Array(@appointment_times[[date, professional.id]])
  end

  def detailed_payload
    {
      days: dates.map do |date|
        {
          date: date.iso8601,
          professionals: @professionals.map do |professional|
            professional_day(date, professional)
          end
        }
      end
    }
  end

  def professional_day(date, professional)
    configured = configured_times(professional, date)
    booked = booked_times(professional, date)
    times = (configured + booked).uniq.sort

    day_blocks = Array(@blocks[[date, professional.id]])
    whole_day_block = day_blocks.find { |block| block.time.nil? }
    blocks_by_time = day_blocks.reject { |block| block.time.nil? }
                               .index_by { |block| block.time.strftime("%H:%M") }

    slots = times.map do |time|
      appointment = Array(@appointments_by_slot[[date, professional.id, time]]).first
      block = whole_day_block || blocks_by_time[time]

      {
        time: time,
        state: slot_state(appointment, block),
        appointment: appointment && AppointmentSerializer.new(
          appointment,
          include_relations: true
        ).as_json,
        block: block && BlockedSlotSerializer.new(block).as_json
      }
    end

    {
      professional: {
        id: professional.id,
        name: professional.name,
        active: professional.active
      },
      slots: slots
    }
  end

  def slot_state(appointment, block)
    return "booked" if appointment
    return "blocked" if block

    "free"
  end

  def summary_payload
    {
      days: dates.map do |date|
        configured = 0
        free = 0
        appointments_count = 0

        @professionals.each do |professional|
          times = configured_times(professional, date)
          booked = booked_times(professional, date)
          configured += times.size
          appointments_count += booked.size

          day_blocks = Array(@blocks[[date, professional.id]])
          next if day_blocks.any? { |block| block.time.nil? }

          blocked_times = day_blocks.filter_map do |block|
            block.time&.strftime("%H:%M")
          end

          free += (times - blocked_times - booked).size
        end

        {
          date: date.iso8601,
          appointments_count: appointments_count,
          free_slots_count: free,
          configured_slots_count: configured
        }
      end
    }
  end
end
