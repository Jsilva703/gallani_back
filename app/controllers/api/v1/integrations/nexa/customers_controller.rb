module Api
  module V1
    module Integrations
      module Nexa
        class CustomersController < Api::BaseController
          def index
            phone = normalize_phone(params.require(:phone))
            customers = Customer.where(phone: phone).order(:id)

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

          def normalize_phone(value)
            value.to_s.gsub(/\D/, "")
          end
        end
      end
    end
  end
end
