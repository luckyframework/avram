class CreateMaterializedViewNames::V20240210233828 < Avram::Migrator::Migration::V1
  def migrate
    execute <<-SQL
    CREATE MATERIALIZED VIEW IF NOT EXISTS all_the_names AS
      SELECT name FROM admins
      UNION ALL
      SELECT name FROM businesses
      UNION ALL
      SELECT name FROM customers
      UNION ALL
      SELECT name FROM employees
      UNION ALL
      SELECT name FROM users
    SQL
  end

  def rollback
    execute <<-SQL
    DROP MATERIALIZED VIEW IF EXISTS all_the_names
    SQL
  end
end
