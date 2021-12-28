require "../../spec_helper"

describe Avram::Migrator::DropTableStatement do
  it "can drop table" do
    statement = Avram::Migrator::DropTableStatement.new(:users).build

    statement.should eq "DROP TABLE users"
  end
end
