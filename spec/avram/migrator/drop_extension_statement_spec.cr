require "../../spec_helper"

describe Avram::Migrator::DropExtensionStatement do
  it "builds the proper SQL for dropping an extension" do
    statement = Avram::Migrator::DropExtensionStatement.new("uuid-ossp")
    statement.build.should eq %{DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;}
  end
end
