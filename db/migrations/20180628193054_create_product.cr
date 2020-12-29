class CreateProduct::V20180628193054 < Avram::Migrator::Migration::V1
  def migrate
    create :products do
      primary_key id : UUID
      add_timestamps
    end
  end

  def rollback
    drop :products
  end
end
