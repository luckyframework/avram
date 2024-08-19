class CreateNotes::V20240818230651 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Note) do
      primary_key id : Int64
      add_timestamps
      add from : String
      add read : Bool, default: false
      add text : String
    end
  end

  def rollback
    drop table_for(Note)
  end
end
