module Sales
  class BuildNumber
    def self.call(terminal_id:, at: Time.current)
      date_part = at.strftime("%Y%m%d")
      prefix    = "#{terminal_id}-#{date_part}"

      last_number = Sale.where("number LIKE ?", "#{prefix}-%").maximum(:number)
      next_seq    = last_number ? last_number.split("-").last.to_i + 1 : 1

      "#{prefix}-#{next_seq.to_s.rjust(4, '0')}"
    end
  end
end
