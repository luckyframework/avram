class CreateVirgin::V20200227193533 < Avram::Migrator::Migration::V1
  def migrate
    create :virgins do
      primary_key id : Int64
      add_timestamps
    end
  end

  def rollback
    drop :virgins
  end
end
