module Api
  module V1
    module Admin
      class AvailabilityExceptionsController < Api::BaseController
        def upsert
          professional = Professional.find(params[:professional_id])
          date = Date.iso8601(params[:date])
          exception = professional.availability_exceptions.find_or_initialize_by(date: date)
          exception.times = params.require(:times)

          if exception.save
            render json: { data: AvailabilityExceptionSerializer.new(exception).as_json }
          else
            render json: { errors: exception.errors }, status: :unprocessable_entity
          end
        rescue Date::Error
          render json: { error: "data inválida" }, status: :unprocessable_entity
        end

        def destroy
          AvailabilityException.find(params[:id]).destroy!
          head :no_content
        end
      end
    end
  end
end
