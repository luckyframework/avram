class CreateBusinessSales::V20201023161820 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(BusinessSale) do
      primary_key id : Int64
      add_timestamps

      add name : String
      add_belongs_to employee : Employee, on_delete: :cascade
    end
  end

  def rollback
    drop table_for(BusinessSale)
  end
end
