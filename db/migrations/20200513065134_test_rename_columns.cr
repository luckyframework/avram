class TestRenameColumns::V20200513065134 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(RenamableOwner) do
      primary_key id : Int64
      add_timestamps
    end

    create table_for(Renamable) do
      primary_key id : Int64
      add_timestamps
      add thingies : JSON::Any
      add gsm_number : String
      add_belongs_to boss : RenamableOwner, on_delete: :cascade
    end

    alter table_for(Renamable) do
      rename :gsm_number, :mobile
      rename_belongs_to :boss, :owner
      rename :thingies, :options
    end
  end

  def rollback
    drop table_for(Renamable)
    drop table_for(RenamableOwner)
  end
end
