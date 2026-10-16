class DashboardService
  def initialize(date: Date.current)
    @date = date
  end

  def call
    month_range = @date.beginning_of_month..@date.end_of_month
    today_appointments = Appointment.includes(:customer, :professional, :service)
                                    .where(date: @date)
                                    .order(:time)
                                    .to_a

    {
      today_revenue: FinancialEntry.income.where(date: @date).sum(:amount).to_f,
      month_revenue: monthly_income(month_range).sum(:amount).to_f,
      average_ticket: monthly_income(month_range).average(:amount).to_f,
      today_appointments_count: today_appointments.size,
      free_slots_today: free_slots_today,
      new_customers: new_customers(month_range),
      recurring_customers: recurring_customers(month_range),
      cancellations: Appointment.where(date: month_range, status: "cancelled").count,
      no_shows: Appointment.where(date: month_range, status: "no_show").count,
      revenue_by_day: revenue_by_day(month_range),
      top_services: top_services(month_range),
      professional_performance: professional_performance(month_range),
      today_appointments: today_appointments.map do |appointment|
        AppointmentSerializer.new(appointment, include_relations: true).as_json
      end
    }
  end

  private

  def monthly_income(range)
    FinancialEntry.income.where(date: range)
  end

  def free_slots_today
    payload = AgendaService.new(
      from: @date.iso8601,
      to: @date.iso8601,
      summary: true
    ).call

    payload[:days].first[:free_slots_count]
  end

  def new_customers(range)
    Customer.where(
      created_at: range.first.beginning_of_day..range.last.end_of_day
    ).count
  end

  def recurring_customers(range)
    Appointment.where(date: range)
               .group(:customer_id)
               .having("COUNT(*) > 1")
               .count
               .size
  end

  def revenue_by_day(range)
    monthly_income(range)
      .group(:date)
      .sum(:amount)
      .sort_by { |date, _| date }
      .map { |date, amount| { date: date.iso8601, amount: amount.to_f } }
  end

  def top_services(range)
    monthly_income(range)
      .joins(:service)
      .group("services.id", "services.name")
      .sum(:amount)
      .sort_by { |_, amount| -amount }
      .first(5)
      .map do |(service_id, name), amount|
        {
          service_id: service_id,
          name: name,
          revenue: amount.to_f
        }
      end
  end

  def professional_performance(range)
    revenue = monthly_income(range)
              .joins(:professional)
              .group("professionals.id", "professionals.name")
              .sum(:amount)

    completed = Appointment.where(date: range, status: "completed")
                           .group(:professional_id)
                           .count

    revenue.map do |(professional_id, name), amount|
      {
        professional_id: professional_id,
        name: name,
        revenue: amount.to_f,
        completed_appointments: completed.fetch(professional_id, 0)
      }
    end
  end
end
