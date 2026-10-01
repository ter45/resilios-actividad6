require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(name: "User Manager", email: "manager@example.test", password: "password123", role: :admin, active: true)
    @cashier = User.create!(name: "Managed Cashier", email: "managed@example.test", password: "password123", role: :cashier, terminal_assigned: "A", active: true)
  end

  def login(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  def attributes(overrides = {})
    { name: "New User", email: "new@example.test", role: "cashier", terminal_assigned: "B", active: "1", password: "newpassword123", password_confirmation: "newpassword123" }.merge(overrides)
  end

  test "administrator sees navigation list and create and edit forms" do
    login(@admin)
    get admin_users_path
    assert_response :success
    assert_select "a[href=?]", admin_users_path, text: "Usuarios"
    assert_select "a[href=?]", new_admin_user_path
    get new_admin_user_path
    assert_response :success
    assert_select "select[name='user[role]'] option", count: 2
    get edit_admin_user_path(@cashier)
    assert_response :success
    assert_select "input[name='user[password]'][value]", count: 0
  end

  test "administrator creates cashier assigned to terminal B without changing own session" do
    login(@admin)
    assert_difference "User.count", 1 do
      post admin_users_path, params: { user: attributes }
    end
    assert_redirected_to admin_users_path
    created = User.find_by!(email: "new@example.test")
    assert created.cashier?
    assert created.valid_password?("newpassword123")
    assert_equal "B", created.terminal_assigned
    get admin_users_path
    assert_response :success
  end

  test "administrator creates another administrator without terminal" do
    login(@admin)
    post admin_users_path, params: { user: attributes(role: "admin", terminal_assigned: "") }
    assert_redirected_to admin_users_path
    created = User.find_by!(email: "new@example.test")
    assert created.admin?
    assert_nil created.terminal_assigned
  end

  test "duplicate email invalid role missing terminal and mismatched passwords are rejected" do
    login(@admin)
    [attributes(email: @cashier.email), attributes(role: "unknown"), attributes(terminal_assigned: ""), attributes(password_confirmation: "different")].each do |invalid|
      assert_no_difference "User.count" do
        post admin_users_path, params: { user: invalid }
      end
      assert_response :unprocessable_entity
      assert_select "[role='alert']"
    end
  end

  test "editing without password preserves credentials and updates terminal" do
    login(@admin)
    digest = @cashier.encrypted_password
    patch admin_user_path(@cashier), params: { user: { name: "Updated Cashier", terminal_assigned: "B", password: "", password_confirmation: "" } }
    assert_redirected_to admin_users_path
    assert_equal digest, @cashier.reload.encrypted_password
    assert_equal "B", @cashier.terminal_assigned
  end

  test "administrator can set a new password" do
    login(@admin)
    patch admin_user_path(@cashier), params: { user: { password: "replacement123", password_confirmation: "replacement123" } }
    assert_redirected_to admin_users_path
    assert @cashier.reload.valid_password?("replacement123")
    assert_not @cashier.valid_password?("password123")
  end

  test "administrator cannot deactivate or demote own account" do
    login(@admin)
    [{ active: "0" }, { role: "cashier", terminal_assigned: "A" }].each do |changes|
      patch admin_user_path(@admin), params: { user: changes }
      assert_response :unprocessable_entity
      assert @admin.reload.active?
      assert @admin.admin?
    end
  end

  test "non administrators cannot view create or update users" do
    %i[cashier supervisor viewer].each do |role|
      @cashier.update!(role: role)
      login(@cashier)
      get admin_users_path
      assert_response :redirect
      get new_admin_user_path
      assert_response :redirect
      get edit_admin_user_path(@admin)
      assert_response :redirect
      assert_no_difference "User.count" do
        post admin_users_path, params: { user: attributes }
      end
      assert_response :redirect
      patch admin_user_path(@cashier), params: { user: { role: "admin" } }
      assert_response :redirect
      assert_equal role.to_s, @cashier.reload.role
      delete destroy_user_session_path
    end
  end

  test "anonymous users cannot manage accounts" do
    get admin_users_path
    assert_redirected_to new_user_session_path
    assert_no_difference "User.count" do
      post admin_users_path, params: { user: attributes }
    end
    assert_redirected_to new_user_session_path
  end

  test "deactivation denies login and activation restores access" do
    login(@admin)
    patch admin_user_path(@cashier), params: { user: { active: "0" } }
    assert_redirected_to admin_users_path
    delete destroy_user_session_path
    login(@cashier)
    get pos_root_path
    assert_redirected_to new_user_session_path
    login(@admin)
    patch admin_user_path(@cashier), params: { user: { active: "1" } }
    assert_redirected_to admin_users_path
    delete destroy_user_session_path
    login(@cashier)
    assert_redirected_to pos_root_path
  end

  test "deactivation blocks an already authenticated session" do
    login(@cashier)
    @cashier.update!(active: false)
    get pos_root_path
    assert_redirected_to new_user_session_path
  end

  test "filters search by email role and state" do
    login(@admin)
    get admin_users_path, params: { q: @cashier.email, role: "cashier", active: "1" }
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "tbody", text: /Managed Cashier/
  end
end