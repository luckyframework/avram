class CreateAttachableItems::V20260314174133 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(AttachableItem) do
      primary_key id : Int64
      add_timestamps

      add image : JSON::Any?
    end
  end

  def rollback
    drop table_for(AttachableItem)
  end
end
