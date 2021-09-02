class CreatePriceForLineItems::V20180627220827 < Avram::Migrator::Migration::V1
  def migrate
    execute <<-SQL
      CREATE TABLE prices (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        in_cents integer NOT NULL,
        line_item_id uuid NOT NULL REFERENCES line_items (id),
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    SQL
  end

  def rollback
    drop :prices
  end
end
