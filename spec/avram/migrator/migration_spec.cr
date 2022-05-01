require "../../spec_helper"

class MigrationThatPartiallyWorks::V999 < Avram::Migrator::Migration::V1
  def migrate
    create :fake_things do
      add foo : String
    end

    alter :table_does_not_exist do
      add foo : String?
    end
  end

  def rollback
  end
end

class MigrationWithOrderDependentExecute::V998 < Avram::Migrator::Migration::V1
  def migrate
    execute "CREATE TABLE execution_order ();"

    alter :execution_order do
      add bar : String?
    end

    execute "ALTER TABLE execution_order ADD new_col text;"
  end

  def rollback
    drop :execution_order
  end
end

class MigrationWithAlterAndFillExisting::V997 < Avram::Migrator::Migration::V1
  def migrate
    execute "CREATE TABLE execution_order (x integer NOT NULL);"
    execute "INSERT INTO execution_order (x) VALUES (1);"

    alter :execution_order do
      add y : Int32, fill_existing_with: "2"
    end
  end

  def rollback
    drop :execution_order
  end
end

class MigrationWithFunctionAndTrigger::V996 < Avram::Migrator::Migration::V1
  def migrate
    create_function "touch_updated_at", <<-SQL
    IF NEW.updated_at IS NULL OR NEW.updated_at = OLD.updated_at THEN
      NEW.updated_at := now();
    END IF;
    RETURN NEW;
    SQL

    create_trigger table_for(User), "trigger_touch_updated_at", "touch_updated_at"
  end

  def rollback
    drop_function "touch_updated_at"
    drop_trigger :users, "trigger_touch_updated_at"
  end
end

describe Avram::Migrator::Migration::V1 do
  it "executes statements in a transaction" do
    expect_raises Avram::FailedMigration do
      MigrationThatPartiallyWorks::V999.new.up
    end

    exists = TestDatabase.run do |db|
      db.query_one? "SELECT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'fake_things');", as: Bool
    end
    exists.should be_false
  end

  describe "statement execution order" do
    it "runs execute statements in the order they were called" do
      begin
        MigrationWithOrderDependentExecute::V998.new.up(quiet: true)
        columns = get_column_names("execution_order")
        columns.includes?({"new_col", true}).should be_true
        columns.includes?({"bar", true}).should be_true
      ensure
        MigrationWithOrderDependentExecute::V998.new.down(quiet: true)
      end
    end
  end

  describe "altering a table with records" do
    it "adds the new column without raising an exception" do
      begin
        MigrationWithAlterAndFillExisting::V997.new.up(quiet: true)
        columns = get_column_names("execution_order")
        columns.includes?({"x", false}).should be_true
        columns.includes?({"y", false}).should be_true
      ensure
        MigrationWithAlterAndFillExisting::V997.new.down(quiet: true)
      end
    end
  end

  describe "helper statements" do
    it "appends function and trigger statments to prepared statements" do
      migration = MigrationWithFunctionAndTrigger::V996.new
      migration.migrate
      sql = migration.prepared_statements.join("\n")

      sql.should contain "CREATE OR REPLACE FUNCTION touch_updated_at"
      sql.should contain "DROP TRIGGER IF EXISTS trigger_touch_updated_at"
      sql.should contain "CREATE TRIGGER trigger_touch_updated_at"
    end
  end
end

private def get_column_names(table_name)
  statement = <<-SQL
  SELECT column_name as name, is_nullable::boolean as nilable
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = '#{table_name}'
  SQL

  TestDatabase.run(&.query_all(statement, as: {String, Bool}))
end
