class CreateTransactions::V20240224173636 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Transaction) do
      primary_key id : Int64
      add_timestamps
      add type : Int32
      add soft_deleted_at : Time?
      add_belongs_to user : User, on_delete: :cascade
    end
  end

  def rollback
    drop table_for(Transaction)
  end
end
