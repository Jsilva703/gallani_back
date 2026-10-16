module Api
  module V1
    module Admin
      class CustomersController < Api::BaseController
        def index
          customers = filter_by_query(Customer.order(:name))

          render json: {
            data: customers.map { |customer| CustomerSerializer.new(customer).as_json }
          }
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

        def filter_by_query(scope)
          query = params[:query].to_s.strip
          return scope if query.blank?

          conditions = [
            "name ILIKE :text_query",
            "email ILIKE :text_query"
          ]
          binds = {
            text_query: "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
          }

          phone_query = query.gsub(/\D/, "")
          if phone_query.present?
            conditions << "phone ILIKE :phone_query"
            binds[:phone_query] = "%#{ActiveRecord::Base.sanitize_sql_like(phone_query)}%"
          end

          scope.where(conditions.join(" OR "), **binds)
        end
      end
    end
  end
end
