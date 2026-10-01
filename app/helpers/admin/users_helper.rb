module Admin::UsersHelper
  def user_role_options(user = nil)
    options = [["Administrador", "admin"], ["Cajero", "cashier"]]
    if user&.persisted? && !%w[admin cashier].include?(user.role)
      options << [user_role_label(user.role), user.role]
    end
    options
  end

  def user_role_label(role)
    { "admin" => "Administrador", "cashier" => "Cajero", "supervisor" => "Supervisor", "viewer" => "Consulta" }.fetch(role, role)
  end
end
