require "../../spec_helper"

describe Avram::Migrator::DropFunctionStatement do
  it "builds the proper SQL for dropping a function" do
    statement = Avram::Migrator::DropFunctionStatement.new("set_updated_at")
    statement.build.should eq %{DROP FUNCTION IF EXISTS "set_updated_at" CASCADE;}
  end
end
