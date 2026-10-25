class AddUniqueConstraintToUsers::V20220113043033 < Avram::Migrator::Migration::V1
  def migrate
    create_index :users, [:name, :nickname], unique: true
  end

  def rollback
    drop_index :users, [:name, :nickname]
  end
end
