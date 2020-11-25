class CreateProduct::V20180628193054 < Avram::Migrator::Migration::V1
  def migrate
    create :products do
      primary_key id : UUID
      add_timestamps
    end

    enable_extension "uuid-ossp"
    execute("ALTER TABLE products ALTER COLUMN id SET DEFAULT uuid_generate_v4();")
  end

  def rollback
    drop :products
  end
end
