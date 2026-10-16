module Api
  module V1
    class CorsController < Api::BaseController
      skip_before_action :authenticate_request!

      def preflight
        head :no_content
      end
    end
  end
end
