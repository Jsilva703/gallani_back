module Api
  module V1
    module Admin
      class FinancialEntriesController < Api::BaseController
        ALLOWED_PER_PAGE = [5, 10, 20].freeze

        def index
          base_relation = FinancialEntry.where(date: date_range)
          relation = base_relation.order(date: :desc, created_at: :desc)
          relation = relation.where(entry_type: params[:type]) if params[:type].present?

          page = [params.fetch(:page, 1).to_i, 1].max
          per_page = params.fetch(:per_page, 10).to_i
          per_page = 10 unless ALLOWED_PER_PAGE.include?(per_page)

          total = relation.count
          entries = relation.includes(:customer, :professional, :service)
                            .offset((page - 1) * per_page)
                            .limit(per_page)

          income_relation = base_relation.income
          income = income_relation.sum(:amount)
          expense = base_relation.expense.sum(:amount)

          render json: {
            data: entries.map { |entry| FinancialEntrySerializer.new(entry).as_json },
            meta: {
              page: page,
              per_page: per_page,
              total: total,
              total_pages: (total.to_f / per_page).ceil
            },
            summary: {
              income: income.to_f,
              expense: expense.to_f,
              balance: (income - expense).to_f,
              average_ticket: income_relation.average(:amount).to_f,
              count: base_relation.count
            }
          }
        rescue Date::Error
          render json: { error: "data inválida" }, status: :unprocessable_entity
        rescue ArgumentError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def date_range
          start_date = params[:start_date].present? ? Date.iso8601(params[:start_date]) : Date.current.beginning_of_month
          end_date = params[:end_date].present? ? Date.iso8601(params[:end_date]) : Date.current.end_of_month

          raise ArgumentError, "período inválido" if end_date < start_date

          start_date..end_date
        end
      end
    end
  end
end
