class CreateManagersAndEmployees::V20171130064637 < Avram::Migrator::Migration::V1
  def migrate
    create :managers do
      add name : String
    end

    create :employees do
      add name : String
      add manager_id : Int32?
    end
  end

  def rollback
    drop :employees
    drop :managers
  end
end
