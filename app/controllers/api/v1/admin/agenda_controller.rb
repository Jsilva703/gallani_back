module Api
  module V1
    module Admin
      class AgendaController < Api::BaseController
        def index
          payload = AgendaService.new(
            from: params.require(:from),
            to: params.require(:to),
            professional_id: params[:professional_id],
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
