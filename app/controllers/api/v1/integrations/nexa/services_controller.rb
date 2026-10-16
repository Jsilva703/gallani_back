module Api
  module V1
    module Integrations
      module Nexa
        class ServicesController < Api::BaseController
          def index
            services = Service.where(active: true).order(:name)
            render json: { data: services.map { |service| ServiceSerializer.new(service).as_json } }
          end
        end
      end
    end
  end
end
