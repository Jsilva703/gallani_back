module Api
  module V1
    module Integrations
      module Nexa
        class AvailabilityController < Api::BaseController
          def show
            professional = Professional.where(active: true).find(params.require(:professional_id))
            date = Date.iso8601(params.require(:date))

            configured = AvailabilityResolver.new(professional: professional, date: date).configured_times

            whole_day_blocked = professional.blocked_slots.where(date: date, time: nil).exists?
            blocked_times = professional.blocked_slots.where(date: date)
                                        .where.not(time: nil)
                                        .pluck(:time)
                                        .map { |time| time.strftime("%H:%M") }

            booked_times = professional.appointments
                                       .where(date: date, status: Appointment::ACTIVE_STATUSES)
                                       .pluck(:time)
                                       .map { |time| time.strftime("%H:%M") }

            available = whole_day_blocked ? [] : configured - blocked_times - booked_times

            render json: {
              professional_id: professional.id,
              date: date.iso8601,
              times: available
            }
          rescue Date::Error
            render json: { error: "data inválida" }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
