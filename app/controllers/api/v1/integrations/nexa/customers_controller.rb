module Api
  module V1
    module Integrations
      module Nexa
        class CustomersController < Api::BaseController
          def index
            phone = normalized_phone!(params.require(:phone))
            customers = Customer.where(phone: phone).order(:id)

            render json: { data: customers.map { |customer| CustomerSerializer.new(customer).as_json } }
          rescue InvalidPhone => e
            render json: { error: e.message }, status: :unprocessable_entity
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

          InvalidPhone = Class.new(StandardError)

          def customer_params
            params.require(:customer).permit(:name, :phone, :email)
          end

          def normalized_phone!(value)
            phone = value.to_s.gsub(/\D/, "")
            return phone if phone.length.in?([10, 11])

            raise InvalidPhone, "telefone deve conter 10 ou 11 dígitos"
          end
        end
      end
    end
  end
end
