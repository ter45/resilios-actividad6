require "vips"

module Tickets
  class Logo
    # ESC/POS GS v 0: width in bytes, height in dots, MSB first.
    # https://download4.epson.biz/sec_pubs/pos/reference_en/escpos/gs_lv_0.html
    def self.call(setting)
      return "".b unless setting.logo.attached?

      width = setting.paper_width_mm == 58 ? 384 : 576
      image = Vips::Image.thumbnail_buffer(setting.logo.download, width, height: 192, size: :down)
      image = image.flatten(background: [255, 255, 255]) if image.has_alpha?
      image = image.colourspace(:b_w).cast(:uchar)
      pixels = image.write_to_memory.bytes
      row_bytes = (image.width + 7) / 8
      raster = Array.new(row_bytes * image.height, 0)
      image.height.times do |y|
        image.width.times do |x|
          raster[y * row_bytes + x / 8] |= 0x80 >> (x % 8) if pixels[y * image.width + x] < 128
        end
      end
      "\x1dv0\x00".b + [row_bytes, image.height].pack("v2") + raster.pack("C*") + "\n".b
    rescue Vips::Error, ActiveStorage::FileNotFoundError => error
      Rails.logger.warn("Ticket logo omitted: #{error.class}")
      "".b
    end
  end
end