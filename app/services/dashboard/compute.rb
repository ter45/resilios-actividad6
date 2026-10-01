module Dashboard
  class Compute
    Result = Struct.new(
      :sales_today,
      :sales_yesterday,
      :credit_today,
      :debt_total,
      :voided_today,
      :sales_count_today,
      :payments_today,
      :stock_low,
      :stock_out,
      :top_debtors,
      :top_products_today,
      :sales_last_7_days,
      :open_credits_count,
      :pending_closings,
      keyword_init: true
    )

    def self.call
      new.call
    end

    def call
      Result.new(
        sales_today:        sales_today_total,
        sales_yesterday:    sales_yesterday_total,
        credit_today:       credit_today_total,
        debt_total:         debt_total,
        voided_today:       voided_today_count,
        sales_count_today:  sales_count_today,
        payments_today:     payments_today_total,
        stock_low:          stock_low,
        stock_out:          stock_out,
        top_debtors:        top_debtors,
        top_products_today: top_products_today,
        sales_last_7_days:  sales_last_7_days,
        open_credits_count: open_credits_count,
        pending_closings:   pending_closings
      )
    end

    private

    def today
      Time.current.beginning_of_day..Time.current.end_of_day
    end

    def yesterday
      (Time.current - 1.day).beginning_of_day..(Time.current - 1.day).end_of_day
    end

    def sales_today_total
      Sale.completed.where(sold_at: today).sum(:total)
    end

    def sales_yesterday_total
      Sale.completed.where(sold_at: yesterday).sum(:total)
    end

    def credit_today_total
      Sale.completed.where(sold_at: today).sum(:credit_amount)
    end

    def debt_total
      Customer.kept.sum(:credit_balance)
    end

    def voided_today_count
      Sale.voided.where(voided_at: today).count
    end

    def sales_count_today
      Sale.completed.where(sold_at: today).count
    end

    def payments_today_total
      Payment.where(paid_at: today).sum(:amount)
    end

    def stock_low
      Product.kept.sellable.low_stock(5).ordered.limit(10)
    end

    def stock_out
      Product.kept.sellable.out_of_stock.ordered.limit(10)
    end

    def top_debtors
      Customer.kept.with_debt.order(credit_balance: :desc).limit(5)
    end

    def top_products_today
      SaleItem.joins(:sale)
              .where(sales: { status: :completed, sold_at: today })
              .group(:product_name)
              .select("product_name, SUM(quantity) AS qty, SUM(line_total) AS revenue")
              .order("revenue DESC")
              .limit(5)
    end

    def sales_last_7_days
      days = 6.downto(0).map { |n| (Date.current - n.days) }
      data = Sale.completed
                 .where(sold_at: 7.days.ago.beginning_of_day..Time.current.end_of_day)
                 .group("DATE(sold_at)")
                 .sum(:total)

      days.map do |day|
        { date: day, total: (data[day] || 0).to_d }
      end
    end

    def open_credits_count
      Credit.pending.count
    end

    def pending_closings
      %w[A B].map do |term|
        last = CashClosing.last_closing_for(term)
        opened_at = last ? last.closed_at : Time.current.beginning_of_day
        count = Sale.completed.where(terminal_id: term, sold_at: opened_at..Time.current).count
        expected = Sale.completed.where(terminal_id: term, sold_at: opened_at..Time.current).sum(:cash_amount)
        { terminal_id: term, sales_count: count, expected_cash: expected, opened_at: opened_at }
      end
    end
  end
end
