class CreateSoftDeletableItems::V20200316160609 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(SoftDeletableItem) do
      primary_key id : Int64
      add_timestamps

      add soft_deleted_at : Time?
    end
  end

  def rollback
    drop table_for(SoftDeletableItem)
  end
end
