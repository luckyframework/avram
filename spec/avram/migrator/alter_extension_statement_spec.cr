require "../../spec_helper"

describe Avram::Migrator::AlterExtensionStatement do
  it "builds the proper SQL to update an extension" do
    statement = Avram::Migrator::AlterExtensionStatement.new("uuid-ossp")
    statement.build.should eq %{ALTER EXTENSION "uuid-ossp" UPDATE;}
  end

  it "updates to a specific version" do
    statement = Avram::Migrator::AlterExtensionStatement.new("hstore", to: "2.0")
    statement.build.should eq %{ALTER EXTENSION "hstore" UPDATE TO '2.0';}
  end
end
