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
            appointment = Appointment.new(appointment_params)

            if appointment.save
              render json: {
                data: AppointmentSerializer.new(appointment, include_relations: true).as_json
              }, status: :created
            else
              render json: { errors: appointment.errors }, status: :unprocessable_entity
            end
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

            Appointment.transaction do
              appointment.update!(
                date: Date.iso8601(params.require(:date)),
                time: params.require(:time),
                status: "scheduled"
              )
            end

            render json: {
              data: AppointmentSerializer.new(appointment, include_relations: true).as_json
            }
          rescue Date::Error
            render json: { error: "data inválida" }, status: :unprocessable_entity
          rescue ActiveRecord::RecordInvalid
            render json: { errors: appointment.errors }, status: :unprocessable_entity
          end

          private

          def appointment_params
            params.require(:appointment).permit(
              :customer_id,
              :professional_id,
              :service_id,
              :date,
              :time,
              :price
            )
          end
        end
      end
    end
  end
end
