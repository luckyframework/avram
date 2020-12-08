class CreateAdminUsersView::V20201202225520 < Avram::Migrator::Migration::V1
  def migrate
    execute <<-SQL
      CREATE VIEW admin_users AS
        SELECT users.*
        FROM users
        JOIN admins on admins.name = users.name;
    SQL
  end

  def rollback
    execute "DROP VIEW admin_users;"
  end
end
