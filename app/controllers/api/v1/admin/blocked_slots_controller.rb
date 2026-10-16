module Api
  module V1
    module Admin
      class BlockedSlotsController < Api::BaseController
        def index
          blocked_slots = BlockedSlot.order(:date, :time)
          blocked_slots = apply_date_filters(blocked_slots)
          blocked_slots = blocked_slots.where(professional_id: params[:professional_id]) if params[:professional_id].present?
          blocked_slots = blocked_slots.where(date: parse_date(params[:date])) if params[:date].present?

          render json: { data: blocked_slots.map { |slot| BlockedSlotSerializer.new(slot).as_json } }
        rescue Date::Error, ArgumentError => e
          render json: { error: e.message.presence || "data inválida" }, status: :unprocessable_entity
        end

        def bulk_create
          professional = Professional.find(bulk_params[:professional_id])
          date = parse_date(bulk_params[:date])
          times = Array(bulk_params[:times])

          return render json: { error: "informe ao menos um horário" }, status: :unprocessable_entity if times.empty?

          if times.include?(nil) && times.length > 1
            return render json: { error: "bloqueio de dia inteiro não pode ser combinado com horários" },
                          status: :unprocessable_entity
          end

          created = BlockedSlot.transaction do
            professional.lock!

            validate_block_request!(professional, date, times)

            times.map do |time|
              professional.blocked_slots.create!(
                date: date,
                time: time,
                reason: bulk_params[:reason]
              )
            end
          end

          render json: { data: created.map { |slot| BlockedSlotSerializer.new(slot).as_json } },
                 status: :created
        rescue Date::Error
          render json: { error: "data inválida" }, status: :unprocessable_entity
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors }, status: :unprocessable_entity
        rescue BlockConflict => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def destroy
          BlockedSlot.find(params[:id]).destroy!
          head :no_content
        end

        private

        BlockConflict = Class.new(StandardError)

        def apply_date_filters(scope)
          from = parse_date(params[:from]) if params[:from].present?
          to = parse_date(params[:to]) if params[:to].present?

          raise ArgumentError, "período inválido" if from && to && to < from

          scope = scope.where("date >= ?", from) if from
          scope = scope.where("date <= ?", to) if to
          scope
        end

        def validate_block_request!(professional, date, times)
          existing = professional.blocked_slots.where(date: date)

          if times == [nil]
            raise BlockConflict, "já existem bloqueios nesta data" if existing.exists?

            active_appointments = professional.appointments.where(
              date: date,
              status: Appointment::ACTIVE_STATUSES
            )
            raise BlockConflict, "não é possível bloquear o dia com agendamentos ativos" if active_appointments.exists?

            return
          end

          raise BlockConflict, "o dia inteiro já está bloqueado" if existing.where(time: nil).exists?

          requested_times = times.compact.map(&:to_s)
          configured_times = AvailabilityResolver.new(professional: professional, date: date).configured_times

          unless requested_times.all? { |time| configured_times.include?(time) }
            raise BlockConflict, "um ou mais horários não fazem parte da disponibilidade configurada"
          end

          active_appointments = professional.appointments.where(
            date: date,
            status: Appointment::ACTIVE_STATUSES
          )

          booked_times = active_appointments.pluck(:time).map { |time| time.strftime("%H:%M") }

          if (requested_times & booked_times).any?
            raise BlockConflict, "um ou mais horários possuem agendamento ativo"
          end
        end

        def bulk_params
          params.require(:blocked_slot).permit(:professional_id, :date, :reason, times: [])
        end

        def parse_date(value)
          Date.iso8601(value.to_s)
        end
      end
    end
  end
end
