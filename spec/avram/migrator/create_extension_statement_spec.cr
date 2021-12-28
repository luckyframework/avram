require "../../spec_helper"

describe Avram::Migrator::CreateExtensionStatement do
  it "builds the proper SQL for creating an extension" do
    statement = Avram::Migrator::CreateExtensionStatement.new("uuid-ossp")
    statement.build.should eq %{CREATE EXTENSION IF NOT EXISTS "uuid-ossp";}
  end
end
