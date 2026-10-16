module Api
  module V1
    module ProfessionalPortal
      class AppointmentsController < BaseController
        def create
          appointment = AppointmentCreationService.new(
            attributes: appointment_params,
            professional: current_professional
          ).call

          render json: {
            data: AppointmentSerializer.new(appointment, include_relations: true).as_json
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors }, status: :unprocessable_entity
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
