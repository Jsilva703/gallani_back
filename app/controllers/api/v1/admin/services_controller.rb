module Api
  module V1
    module Admin
      class ServicesController < Api::BaseController
        def index
          services = filter_by_active(filter_by_query(Service.order(:name)))

          render json: { data: services.map { |service| ServiceSerializer.new(service).as_json } }
        end

        def create
          service = Service.new(service_params)

          if service.save
            render json: { data: ServiceSerializer.new(service).as_json }, status: :created
          else
            render json: { errors: service.errors }, status: :unprocessable_entity
          end
        end

        def update
          service = Service.find(params[:id])

          if service.update(service_params)
            render json: { data: ServiceSerializer.new(service).as_json }
          else
            render json: { errors: service.errors }, status: :unprocessable_entity
          end
        end

        private

        def service_params
          params.require(:service).permit(:name, :description, :price, :active)
        end

        def filter_by_query(scope)
          return scope if params[:query].blank?

          query = ActiveRecord::Base.sanitize_sql_like(params[:query].strip)
          scope.where("name ILIKE :query OR description ILIKE :query", query: "%#{query}%")
        end

        def filter_by_active(scope)
          return scope unless params.key?(:active)

          scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
        end
      end
    end
  end
end
