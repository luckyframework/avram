class CreateTokens::V20221015145114 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Token) do
      primary_key id : Int64

      add_timestamps

      add name : String
      add scopes : Array(String)
    end
  end

  def rollback
    drop table_for(Token)
  end
end
