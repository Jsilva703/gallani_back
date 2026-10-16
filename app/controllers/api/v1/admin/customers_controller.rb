module Api
  module V1
    module Admin
      class CustomersController < Api::BaseController
        def index
          customers = Customer.order(:name)
          render json: { data: customers.map { |customer| CustomerSerializer.new(customer).as_json } }
        end

        def create
          customer = Customer.new(customer_params)

          if customer.save
            render json: { data: CustomerSerializer.new(customer).as_json }, status: :created
          else
            render json: { errors: customer.errors }, status: :unprocessable_entity
          end
        end

        private

        def customer_params
          params.require(:customer).permit(:name, :phone, :email)
        end
      end
    end
  end
end
