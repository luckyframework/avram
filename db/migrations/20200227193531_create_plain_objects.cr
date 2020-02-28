class CreatePlainModels::V20200227193533 < Avram::Migrator::Migration::V1
  def migrate
    create :plain_models do
      primary_key id : Int64
      add_timestamps
    end
  end

  def rollback
    drop :plain_models
  end
end
