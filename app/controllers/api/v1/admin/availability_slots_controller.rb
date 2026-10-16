module Api
  module V1
    module Admin
      class AvailabilitySlotsController < Api::BaseController
        def create
          slot = AvailabilitySlot.new(slot_params)

          if slot.save
            render json: { data: AvailabilitySlotSerializer.new(slot).as_json }, status: :created
          else
            render json: { errors: slot.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          AvailabilitySlot.find(params[:id]).destroy!
          head :no_content
        end

        private

        def slot_params
          params.require(:availability_slot).permit(:professional_id, :weekday, :time)
        end
      end
    end
  end
end
