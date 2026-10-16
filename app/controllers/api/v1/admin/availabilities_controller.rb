module Api
  module V1
    module Admin
      class AvailabilitiesController < Api::BaseController
        def show
          professional = Professional.find(params[:professional_id])

          render json: {
            slots: professional.availability_slots.order(:weekday, :time).map do |slot|
              AvailabilitySlotSerializer.new(slot).as_json
            end,
            exceptions: professional.availability_exceptions.order(:date).map do |exception|
              AvailabilityExceptionSerializer.new(exception).as_json
            end
          }
        end

        def copy
          professional = Professional.find(params[:professional_id])
          from_weekday = Integer(params.require(:from_weekday))
          to_weekdays = Array(params.require(:to_weekdays)).map { |weekday| Integer(weekday) }.uniq

          unless (0..6).cover?(from_weekday) && to_weekdays.all? { |weekday| (0..6).cover?(weekday) }
            return render json: { error: "weekday deve estar entre 0 e 6" }, status: :unprocessable_entity
          end

          source_slots = professional.availability_slots.where(weekday: from_weekday).order(:time).to_a

          AvailabilitySlot.transaction do
            to_weekdays.each do |weekday|
              professional.availability_slots.where(weekday: weekday).delete_all

              source_slots.each do |source|
                professional.availability_slots.create!(
                  weekday: weekday,
                  time: source.time,
                  active: source.active
                )
              end
            end
          end

          render json: {
            slots: professional.availability_slots.order(:weekday, :time).map do |slot|
              AvailabilitySlotSerializer.new(slot).as_json
            end
          }
        rescue ArgumentError, TypeError
          render json: { error: "weekday inválido" }, status: :unprocessable_entity
        end
      end
    end
  end
end
