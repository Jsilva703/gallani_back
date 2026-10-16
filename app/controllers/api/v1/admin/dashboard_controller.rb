module Api
  module V1
    module Admin
      class DashboardController < Api::BaseController
        def show
          date = params[:date].present? ? Date.iso8601(params[:date]) : Date.current
          render json: DashboardService.new(date: date).call
        rescue Date::Error
          render json: { error: "data inválida" }, status: :unprocessable_entity
        end
      end
    end
  end
end
