require "test_helper"
require "base64"
require "tempfile"

class BusinessLogoTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(name: "Logo Admin", email: "logo@example.test", password: "password123", role: :admin, active: true)
    @setting = Setting.current
    @uploads = []
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  teardown do
    @setting.reload.logo.purge if @setting.reload.logo.attached?
    @uploads.each(&:close!)
  end

  def upload(content: nil, type: "image/png", extension: ".png")
    file = Tempfile.new(["logo", extension])
    file.binmode
    file.write(content || Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII="))
    file.rewind
    @uploads << file
    Rack::Test::UploadedFile.new(file.path, type)
  end

  test "form accepts multipart image uploads" do
    get edit_admin_setting_path
    assert_response :success
    assert_select "form[enctype='multipart/form-data']"
    assert_select "input[type='file'][name='setting[logo]']"
  end

  test "administrator can upload view and replace the logo" do
    patch admin_setting_path, params: { setting: { logo: upload } }
    assert_redirected_to edit_admin_setting_path
    assert @setting.reload.logo.attached?
    original_id = @setting.logo.blob.id
    get edit_admin_setting_path
    assert_response :success
    assert_select "img[alt=?]", "Logo de #{@setting.business_name}"
    get rails_blob_path(@setting.logo, only_path: true)
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal "image/png", response.media_type
    patch admin_setting_path, params: { setting: { logo: upload } }
    assert_redirected_to edit_admin_setting_path
    assert_not_equal original_id, @setting.reload.logo.blob.id
  end

  test "saving other settings without a file preserves the logo" do
    patch admin_setting_path, params: { setting: { logo: upload } }
    blob_id = @setting.reload.logo.blob.id
    patch admin_setting_path, params: { setting: { business_name: "Nuevo negocio", logo: "" } }
    assert_redirected_to edit_admin_setting_path
    assert_equal blob_id, @setting.reload.logo.blob.id
    assert_equal "Nuevo negocio", @setting.business_name
  end

  test "invalid replacement preserves the saved logo" do
    patch admin_setting_path, params: { setting: { logo: upload } }
    blob_id = @setting.reload.logo.blob.id
    patch admin_setting_path, params: { setting: { logo: upload(content: "not an image", type: "text/plain", extension: ".txt") } }
    assert_response :unprocessable_entity
    assert_equal blob_id, @setting.reload.logo.blob.id
  end

  test "oversized images and invalid settings do not persist attachments" do
    patch admin_setting_path, params: { setting: { logo: upload(content: "x" * (2.megabytes + 1)) } }
    assert_response :unprocessable_entity
    assert_includes response.body, "debe pesar como máximo 2 MB"
    assert_not @setting.reload.logo.attached?
    patch admin_setting_path, params: { setting: { business_name: "", logo: upload } }
    assert_response :unprocessable_entity
    assert_not @setting.reload.logo.attached?
  end

  test "cashier cannot upload a logo" do
    delete destroy_user_session_path
    cashier = User.create!(name: "Logo Cashier", email: "logo.cashier@example.test", password: "password123", role: :cashier, terminal_assigned: "A", active: true)
    post user_session_path, params: { user: { email: cashier.email, password: "password123" } }
    patch admin_setting_path, params: { setting: { logo: upload } }
    assert_response :redirect
    assert_not @setting.reload.logo.attached?
  end
end