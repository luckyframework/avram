class CreateNicknameInfosView::V20201202231134 < Avram::Migrator::Migration::V1
  def migrate
    execute <<-SQL
      CREATE VIEW nickname_infos AS
        SELECT users.nickname, COUNT(nickname)
        FROM users
        GROUP BY nickname;
    SQL
  end

  def rollback
    execute "DROP VIEW nickname_infos;"
  end
end
