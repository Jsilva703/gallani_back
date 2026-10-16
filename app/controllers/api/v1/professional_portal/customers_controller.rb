module Api
  module V1
    module ProfessionalPortal
      class CustomersController < BaseController
        MAX_RESULTS = 20

        def index
          query = params[:query].to_s.strip
          return render json: { data: [] } if query.blank?

          text_query = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
          phone_query = "%#{ActiveRecord::Base.sanitize_sql_like(query.gsub(/\D/, ""))}%"

          customers = Customer
                      .where(
                        "name ILIKE :text_query OR email ILIKE :text_query OR phone ILIKE :phone_query",
                        text_query: text_query,
                        phone_query: phone_query
                      )
                      .order(:name)
                      .limit(MAX_RESULTS)

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
      end
    end
  end
end
