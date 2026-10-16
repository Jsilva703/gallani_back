module Api
  module V1
    module Integrations
      module Nexa
        class AppointmentsController < Api::BaseController
          def show
            appointment = Appointment.includes(:customer, :professional, :service).find(params[:id])
            render json: { data: AppointmentSerializer.new(appointment, include_relations: true).as_json }
          end

          def create
            appointment = AppointmentCreationService.new(attributes: appointment_params).call

            render json: {
              data: AppointmentSerializer.new(appointment, include_relations: true).as_json
            }, status: :created
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors }, status: :unprocessable_entity
          end

          def cancel
            appointment = Appointment.find(params[:id])
            appointment, = AppointmentStatusService.new(
              appointment: appointment,
              target_status: "cancelled"
            ).call

            render json: {
              data: AppointmentSerializer.new(appointment, include_relations: true).as_json
            }
          rescue AppointmentStatusService::InvalidTransition => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def reschedule
            appointment = Appointment.find(params[:id])
            appointment = AppointmentRescheduleService.new(
              appointment: appointment,
              date: params.require(:date),
              time: params.require(:time)
            ).call

            render json: {
              data: AppointmentSerializer.new(appointment, include_relations: true).as_json
            }
          rescue Date::Error
            render json: { error: "data inválida" }, status: :unprocessable_entity
          rescue AppointmentRescheduleService::InvalidStatus => e
            render json: { error: e.message }, status: :unprocessable_entity
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors }, status: :unprocessable_entity
          end

          private

          def appointment_params
            params.require(:appointment).permit(
              :customer_id,
              :professional_id,
              :service_id,
              :date,
              :time
            )
          end
        end
      end
    end
  end
end
