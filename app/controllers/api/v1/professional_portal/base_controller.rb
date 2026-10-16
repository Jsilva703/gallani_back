module Api
  module V1
    module ProfessionalPortal
      class BaseController < Api::BaseController
        private

        def current_professional
          current_user.professional || raise(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
