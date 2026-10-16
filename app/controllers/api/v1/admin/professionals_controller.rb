module Api
  module V1
    module Admin
      class ProfessionalsController < Api::BaseController
        def index
          professionals = Professional.includes(:services).order(:name)
          professionals = filter_by_query(professionals)
          professionals = filter_by_active(professionals)

          include_services = params[:include].to_s.split(",").include?("services")

          render json: {
            data: professionals.map do |professional|
              ProfessionalSerializer.new(professional, include_services: include_services).as_json
            end
          }
        end

        def create
          attributes = create_params
          service_ids = attributes.delete(:service_ids)

          return render_missing_services if service_ids.blank?

          services = find_services(service_ids)
          return render_invalid_services if services.nil?

          professional = Professional.new(attributes)

          Professional.transaction do
            professional.save!
            professional.services = services
          end

          render json: { data: ProfessionalSerializer.new(professional).as_json }, status: :created
        rescue ActiveRecord::RecordInvalid
          render json: { errors: professional.errors }, status: :unprocessable_entity
        end

        def update
          professional = Professional.find(params[:id])
          attributes = update_params
          service_ids_present = attributes.key?(:service_ids)
          service_ids = attributes.delete(:service_ids)

          return render_missing_services if service_ids_present && service_ids.blank?

          services = service_ids_present ? find_services(service_ids) : nil
          return render_invalid_services if service_ids_present && services.nil?

          Professional.transaction do
            professional.update!(attributes)
            professional.services = services if service_ids_present
          end

          render json: { data: ProfessionalSerializer.new(professional).as_json }
        rescue ActiveRecord::RecordInvalid
          render json: { errors: professional.errors }, status: :unprocessable_entity
        end

        private

        def create_params
          params.require(:professional).permit(:name, :phone, service_ids: [])
        end

        def update_params
          params.require(:professional).permit(:name, :phone, :active, service_ids: [])
        end

        def find_services(service_ids)
          ids = service_ids.map(&:to_i).uniq
          services = Service.where(id: ids).to_a
          services.size == ids.size ? services : nil
        end

        def filter_by_query(scope)
          return scope if params[:query].blank?

          query = ActiveRecord::Base.sanitize_sql_like(params[:query].strip)
          scope.where("name ILIKE :query OR phone ILIKE :query", query: "%#{query}%")
        end

        def filter_by_active(scope)
          return scope unless params.key?(:active)

          scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
        end

        def render_missing_services
          render json: { errors: { services: ["selecione ao menos um serviço"] } },
                 status: :unprocessable_entity
        end

        def render_invalid_services
          render json: { errors: { services: ["contém serviço inválido"] } },
                 status: :unprocessable_entity
        end
      end
    end
  end
end
