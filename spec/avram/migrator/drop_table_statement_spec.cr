require "../../spec_helper"

describe Avram::Migrator::DropTableStatement do
  it "can drop table" do
    statement = Avram::Migrator::DropTableStatement.new(:users).build

    statement.should eq "DROP TABLE users;"
  end

  context "IF EXISTS" do
    it "adds the option to the table" do
      statement = Avram::Migrator::DropTableStatement.new(:users, if_exists: true).build
      statement.should eq "DROP TABLE IF EXISTS users;"
    end
  end
end
