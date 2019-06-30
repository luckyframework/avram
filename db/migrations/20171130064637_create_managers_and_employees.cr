class CreateManagersAndEmployees::V20171130064637 < Avram::Migrator::Migration::V1
  def migrate
    create :managers do
      primary_key id : Int64
      add_timestamps
      add name : String
    end

    create :employees do
      primary_key id : Int64
      add_timestamps
      add name : String
      add manager_id : Int64?
    end
  end

  def rollback
    drop :employees
    drop :managers
  end
end
