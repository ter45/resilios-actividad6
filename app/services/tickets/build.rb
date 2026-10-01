module Tickets
  class Build
    ESC = "\e"
    GS  = "\x1d"

    INIT          = "#{ESC}@"
    ALIGN_LEFT    = "#{ESC}a0"
    ALIGN_CENTER  = "#{ESC}a1"
    ALIGN_RIGHT   = "#{ESC}a2"
    BOLD_ON       = "#{ESC}E1"
    BOLD_OFF      = "#{ESC}E0"
    DOUBLE_ON     = "#{GS}!\x11"
    DOUBLE_OFF    = "#{GS}!\x00"
    UNDERLINE_ON  = "#{ESC}-1"
    UNDERLINE_OFF = "#{ESC}-0"
    LF            = "\n"
    CUT           = "#{GS}V\x42\x00"
    CODEPAGE_LATIN = "#{ESC}t\x13"

    def initialize(sale:, setting: Setting.current)
      @sale    = sale
      @setting = setting
      @width   = setting.chars_per_line
      @out     = []
    end

    def call
      header
      sale_info
      items
      totals
      payment
      customer_section
      footer
      @out.map(&:b).join
    end

    private

    def header
      @out << INIT
      @out << CODEPAGE_LATIN
      @out << ALIGN_CENTER

      @out << Tickets::Logo.call(@setting)
      @out << BOLD_ON << DOUBLE_ON
      @out << @setting.business_name.to_s << LF
      @out << DOUBLE_OFF << BOLD_OFF

      @out << @setting.legal_name.to_s << LF if @setting.legal_name.present?
      @out << "NIT: #{@setting.nit}" << LF if @setting.nit.present?
      @out << @setting.address.to_s << LF if @setting.address.present?
      @out << "#{@setting.city.presence} Tel: #{@setting.phone}".strip << LF if @setting.phone.present? || @setting.city.present?
      @out << @setting.ticket_header.to_s << LF if @setting.ticket_header.present?
      separator
    end

    def sale_info
      @out << ALIGN_LEFT
      @out << pad_line("Ticket:",  @sale.number)
      @out << pad_line("Fecha:",   @sale.sold_at&.strftime("%d/%m/%Y %H:%M"))
      @out << pad_line("Cajero:",  @sale.user.display_name)
      @out << pad_line("Terminal:", @sale.terminal_id)
      separator
    end

    def items
      @out << ALIGN_LEFT << BOLD_ON
      @out << "PRODUCTO" << LF
      @out << BOLD_OFF
      @sale.sale_items.ordered.each do |item|
        @out << item.product_name.to_s << LF
        qty   = item.weight? ? "%.3f kg" % item.quantity : item.quantity.to_i.to_s
        line  = "  #{qty} x $#{int_money(item.unit_price)}"
        total = "$#{int_money(item.line_total)}"
        @out << ljust_rjust(line, total)
      end
      separator
    end

    def totals
      @out << ALIGN_LEFT
      @out << pad_money("Subtotal", @sale.subtotal)
      @out << pad_money("IVA",      @sale.tax_total) if @sale.tax_total.positive?
      @out << pad_money("Descuento", -@sale.discount_total) if @sale.discount_total.positive?
      @out << BOLD_ON << DOUBLE_ON
      @out << pad_money("TOTAL", @sale.total)
      @out << DOUBLE_OFF << BOLD_OFF
      separator
    end

    def payment
      @out << ALIGN_LEFT
      method_label = case @sale.payment_method
                     when "cash"   then "EFECTIVO"
                     when "credit" then "CREDITO"
                     when "mixed"  then "MIXTO"
                     end
      @out << pad_line("Pago:", method_label)
      if @sale.mixed?
        @out << pad_money("  Efectivo", @sale.cash_amount)
        @out << pad_money("  Credito",  @sale.credit_amount)
      end
      separator
    end

    def customer_section
      return unless @sale.customer
      @out << ALIGN_LEFT << BOLD_ON
      @out << "CLIENTE" << LF
      @out << BOLD_OFF
      @out << @sale.customer.name << LF
      @out << @sale.customer.display_document << LF if @sale.customer.document_number.present?
      separator
    end

    def footer
      @out << ALIGN_CENTER
      if @setting.ticket_footer.present?
        @out << @setting.ticket_footer.to_s << LF
      else
        @out << "Gracias por su compra" << LF
      end
      @out << LF << LF << LF
      @out << CUT
    end

    def separator
      @out << ("-" * @width) << LF
    end

    def int_money(n)
      n.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse
    end

    def pad_line(label, value)
      v = value.to_s
      space = [@width - label.length - v.length, 1].max
      "#{label}#{' ' * space}#{v}#{LF}"
    end

    def pad_money(label, amount)
      pad_line(label, "$ #{int_money(amount)}")
    end

    def ljust_rjust(left, right)
      space = [@width - left.length - right.length, 1].max
      "#{left}#{' ' * space}#{right}#{LF}"
    end
  end
end
