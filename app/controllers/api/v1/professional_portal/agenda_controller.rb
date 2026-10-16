module Api
  module V1
    module ProfessionalPortal
      class AgendaController < BaseController
        def index
          payload = AgendaService.new(
            from: params.require(:from),
            to: params.require(:to),
            professional_id: current_professional.id,
            summary: params[:summary]
          ).call

          render json: payload
        rescue Date::Error, ArgumentError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
