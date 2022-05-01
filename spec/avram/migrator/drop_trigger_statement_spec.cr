require "../../spec_helper"

describe Avram::Migrator::DropTriggerStatement do
  it "builds the proper SQL for dropping a trigger" do
    statement = Avram::Migrator::DropTriggerStatement.new(:users, "trigger_set_timestamp")
    statement.build.should eq %{DROP TRIGGER IF EXISTS trigger_set_timestamp ON users;}
  end
end
