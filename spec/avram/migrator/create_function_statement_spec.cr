require "../../spec_helper"

describe Avram::Migrator::CreateFunctionStatement do
  it "builds the proper SQL for creating a function" do
    sql = <<-SQL
    IF NEW.updated_at IS NULL OR NEW.updated_at = OLD.updated_at THEN
      NEW.updated_at := now();
    END IF;
    RETURN NEW;
    SQL
    statement = Avram::Migrator::CreateFunctionStatement.new("set_updated_at", sql)

    full_statement = statement.build
    full_statement.should contain "CREATE OR REPLACE FUNCTION set_updated_at()"
    full_statement.should contain "RETURNS trigger"
    full_statement.should contain "IF NEW.updated_at IS NULL OR NEW.updated_at = OLD.updated_at THEN"
  end

  it "builds more complex functions" do
    sql = "RETURN i + 1;"
    statement = Avram::Migrator::CreateFunctionStatement.new("increment(i integer)", sql, returns: "integer")

    full_statement = statement.build
    full_statement.should contain "CREATE OR REPLACE FUNCTION increment(i integer)"
    full_statement.should contain "RETURNS integer"
    full_statement.should contain "RETURN i + 1;"
  end
end
