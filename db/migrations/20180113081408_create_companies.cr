class CreateCompanies::V20180113081408 < Avram::Migrator::Migration::V1
  def migrate
    create :companies do
      primary_key id : Int64
      add_timestamps
      add sales : Int64
      add earnings : Float64
    end
  end

  def rollback
    drop :companies
  end
end
