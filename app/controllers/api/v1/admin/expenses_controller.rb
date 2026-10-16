module Api
  module V1
    module Admin
      class ExpensesController < Api::BaseController
        def create
          entry = FinancialEntry.new(expense_params.merge(entry_type: "expense"))

          if entry.save
            render json: { data: FinancialEntrySerializer.new(entry).as_json }, status: :created
          else
            render json: { errors: entry.errors }, status: :unprocessable_entity
          end
        end

        private

        def expense_params
          params.require(:expense).permit(:description, :category, :date, :amount)
        end
      end
    end
  end
end
