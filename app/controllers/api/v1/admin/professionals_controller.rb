module Api
  module V1
    module Admin
    class ProfessionalsController < Api::BaseController
      def create
        professional = Professional.new(professional_params)

        if professional.save
          render json: ProfessionalSerializer.new(professional), status: :created
        else
          render json: { errors: professional.errors }, status: :unprocessable_entity
        end
      end

      private

      def professional_params
        params.require(:professional).permit(:name, :phone)
      end
    end
    end
  end
end