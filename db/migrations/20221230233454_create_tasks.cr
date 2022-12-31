class CreateTasks::V20221230233454 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Task) do
      primary_key id : Int64
      add_timestamps

      add title : String
      add body : String?
      add completed_at : Time?
    end
  end

  def rollback
    drop table_for(Task)
  end
end
