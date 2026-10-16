module Api
  module V1
    module ProfessionalPortal
      class ProfileController < BaseController
        def show
          render json: {
            data: {
              user: {
                id: current_user.id,
                name: current_user.name,
                email: current_user.email,
                role: current_user.role
              },
              professional: ProfessionalSerializer.new(
                current_professional,
                include_services: true
              ).as_json
            }
          }
        end
      end
    end
  end
end
