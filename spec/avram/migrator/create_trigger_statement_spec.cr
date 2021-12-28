require "../../spec_helper"

describe Avram::Migrator::CreateTriggerStatement do
  it "builds the proper SQL for creating a before update trigger" do
    statement = Avram::Migrator::CreateTriggerStatement.new(:users, "trigger_set_timestamp", function: "set_timestamp")

    full_statement = statement.build
    full_statement.should eq <<-SQL
    CREATE TRIGGER trigger_set_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE PROCEDURE set_timestamp();
    SQL
  end

  it "builds the statement for after trigger on insert, update, and delete" do
    statement = Avram::Migrator::CreateTriggerStatement.new(:users, "trigger_update_counts", function: "update_counts", callback: :after, on: [:insert, :update, :delete])

    full_statement = statement.build
    full_statement.should eq <<-SQL
    CREATE TRIGGER trigger_update_counts
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE PROCEDURE update_counts();
    SQL
  end
end
