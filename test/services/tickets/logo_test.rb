require "test_helper"
require "vips"

class TicketLogoTest < ActiveSupport::TestCase
  setup do
    @setting = Setting.current
    @setting.update!(business_name: "Granja Ñandú", paper_width_mm: 58)
  end

  teardown do
    @setting.logo.purge if @setting.logo.attached?
  end

  def attach(image)
    @setting.logo.attach(io: StringIO.new(image.write_to_buffer(".png")), filename: "logo.png", content_type: "image/png")
  end

  test "black pixels produce MSB first raster bytes with padded final byte" do
    attach(Vips::Image.black(9, 2))
    data = Tickets::Logo.call(@setting)
    assert_equal "\x1dv0\x00".b, data.byteslice(0, 4)
    assert_equal [2, 2], data.byteslice(4, 4).unpack("v2")
    assert_equal [255, 128, 255, 128], data.byteslice(8, 4).bytes
  end

  test "transparent pixels print white" do
    attach(Vips::Image.black(8, 1, bands: 4).copy(interpretation: :srgb))
    assert_equal [0], Tickets::Logo.call(@setting).byteslice(8, 1).bytes
  end

  test "large logo fits both paper widths and height limit" do
    attach(Vips::Image.black(1000, 200))
    [58, 80].each do |paper|
      @setting.update!(paper_width_mm: paper)
      data = Tickets::Logo.call(@setting)
      width_bytes, height = data.byteslice(4, 4).unpack("v2")
      assert_equal(paper == 58 ? 48 : 72, width_bytes)
      assert_operator height, :<=, 192
      assert_equal 8 + width_bytes * height + 1, data.bytesize
    end
  end

  test "ticket includes logo once before business name without corrupting binary or accented text" do
    attach(Vips::Image.black(9, 2))
    cashier = User.create!(name: "Print Admin", email: "print@example.test", role: :admin, password: "password123")
    product = Product.create!(name: "Maíz", category: Category.create!(name: "Print Category"), stock: 5, price: 100, tax_rate: 0)
    result = Sales::Create.new(cashier: cashier, terminal_id: "A", items: [{ product_id: product.id, quantity: 1 }]).call
    assert result.success?, result.errors.inspect
    bytes = Tickets::Build.new(sale: result.sale, setting: @setting).call
    assert_equal Encoding::BINARY, bytes.encoding
    assert_equal 1, bytes.scan("\x1dv0\x00".b).size
    assert_operator bytes.index("\x1dv0\x00".b), :<, bytes.index("Granja Ñandú".b)
    assert_includes bytes, "Maíz".b
    assert_equal bytes, Base64.decode64(Base64.strict_encode64(bytes))
  end

  test "no logo or damaged image does not prevent a text ticket" do
    assert_equal "".b, Tickets::Logo.call(@setting)
    @setting.logo.attach(io: StringIO.new("invalid image"), filename: "bad.png", content_type: "image/png", identify: false)
    assert_equal "".b, Tickets::Logo.call(@setting)
  end
end