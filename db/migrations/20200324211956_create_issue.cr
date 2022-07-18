class CreateIssue::V20200324211956 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Issue) do
      primary_key id : Int64
      add status : Int32
      add role : Int32
      add permissions : Int64
      add_timestamps
    end
  end

  def rollback
    drop table_for(Issue)
  end
end
