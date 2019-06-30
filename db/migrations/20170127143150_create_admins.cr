class CreateAdmins::V20170127143150 < Avram::Migrator::Migration::V1
  def migrate
    create :admins do
      primary_key id : Int64
      add_timestamps
      add name : String
    end
  end

  def rollback
    drop :admins
  end
end
