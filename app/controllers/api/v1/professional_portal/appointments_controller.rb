module Api
  module V1
    module ProfessionalPortal
      class AppointmentsController < BaseController
        def create
          appointment = current_professional.appointments.new(appointment_params)

          if appointment.save
            render json: {
              data: AppointmentSerializer.new(appointment, include_relations: true).as_json
            }, status: :created
          else
            render json: { errors: appointment.errors }, status: :unprocessable_entity
          end
        end

        private

        def appointment_params
          params.require(:appointment).permit(
            :customer_id,
            :service_id,
            :date,
            :time
          )
        end
      end
    end
  end
end
