class MakeTokensNextIdUnique::V20260427115611 < Avram::Migrator::Migration::V1
  def migrate
    create_index table_for(Token), :next_id, unique: true
  end

  def rollback
    drop_index table_for(Token), :next_id, if_exists: true
  end
end
