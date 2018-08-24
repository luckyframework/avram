require "../spec_helper"

describe LuckyRecord::Migrator::DropTableStatement do
  it "can drop table" do
    statement = LuckyRecord::Migrator::DropTableStatement.new(:users).build

    statement.should eq "DROP TABLE users"
  end
end
