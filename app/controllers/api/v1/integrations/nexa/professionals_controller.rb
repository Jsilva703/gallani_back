module Api
  module V1
    module Integrations
      module Nexa
        class ProfessionalsController < Api::BaseController
          def index
            professionals = Professional.where(active: true)
                                        .includes(:services)
                                        .order(:name)

            if params[:service_id].present?
              professionals = professionals.joins(:services)
                                           .where(services: {
                                             id: params[:service_id],
                                             active: true
                                           })
                                           .distinct
            end

            render json: {
              data: professionals.map { |professional| integration_payload(professional) }
            }
          end

          private

          def integration_payload(professional)
            active_services = professional.services.select(&:active?)

            {
              id: professional.id,
              name: professional.name,
              service_ids: active_services.map(&:id),
              services: active_services.map do |service|
                {
                  id: service.id,
                  name: service.name,
                  description: service.description,
                  price: service.price.to_f
                }
              end
            }
          end
        end
      end
    end
  end
end
