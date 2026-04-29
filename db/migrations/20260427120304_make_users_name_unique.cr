class MakeUsersNameUnique::V20260427120304 < Avram::Migrator::Migration::V1
  def migrate
    create_index table_for(Users), [:name, :nickname], unique: true
  end

  def rollback
    drop_index table_for(Users), [:name, :nickname], if_exists: true
  end
end
