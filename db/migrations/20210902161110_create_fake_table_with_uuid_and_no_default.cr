class CreateFakeTableWithUUIDAndNoDefault::V20210902161110 < Avram::Migrator::Migration::V1
  def migrate
    # This tests that the SchemaEnforcer catches
    # that there's no default here
    execute <<-SQL
      CREATE TABLE unused_uuid_table (
        id uuid PRIMARY KEY,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    SQL
  end

  def rollback
    drop :unused_uuid_table
  end
end
