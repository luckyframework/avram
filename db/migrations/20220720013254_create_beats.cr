class CreateBeats::V20220720013254 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Beat) do
      primary_key id : Int64
      add_timestamps
      add hash : Bytes
    end
  end

  def rollback
    drop table_for(Beat)
  end
end
