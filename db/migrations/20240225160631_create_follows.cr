class CreateFollows::V20240225160631 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Follow) do
      primary_key id : Int64
      add_timestamps
      add soft_deleted_at : Time?
      add_belongs_to follower : User, on_delete: :cascade
      add_belongs_to followee : User, on_delete: :cascade
    end
  end

  def rollback
    drop table_for(Follow)
  end
end
