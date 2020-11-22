class CreateCustomers::V20201111220713 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Customer) do
      primary_key id : Int64
      add_timestamps

      add name : String
      add_belongs_to employee : Employee, on_delete: :cascade
    end
  end

  def rollback
    drop table_for(Customer)
  end
end
