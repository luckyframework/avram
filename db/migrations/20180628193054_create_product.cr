class CreateProduct::V20180628193054 < Avram::Migrator::Migration::V1
  def migrate
    create :products, primary_key_type: :uuid
  end

  def rollback
    drop :products
  end
end
