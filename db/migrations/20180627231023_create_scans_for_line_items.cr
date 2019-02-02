class CreateScansForLineItems::V20180627231023 < Avram::Migrator::Migration::V1
  def migrate
    execute <<-SQL
      CREATE TABLE scans (
        id serial PRIMARY KEY,
        scanned_at timestamp with time zone NOT NULL,
        line_item_id uuid NOT NULL REFERENCES line_items (id),
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    SQL
  end

  def rollback
    drop :scans
  end
end
