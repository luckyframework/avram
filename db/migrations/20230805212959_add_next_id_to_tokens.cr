class AddNextIdToTokens::V20230805212959 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(Token) do
      add next_id : Int32, default: 0
    end
  end

  def rollback
    alter table_for(Token) do
      remove :next_id
    end
  end
end
