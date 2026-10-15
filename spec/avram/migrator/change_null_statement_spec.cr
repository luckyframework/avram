require "../../spec_helper"

describe Avram::Migrator::ChangeNullStatement do
  it "generates correct sql" do
    statement = Avram::Migrator::ChangeNullStatement.new(:users, :email, required: true).build
    statement.should eq %(ALTER TABLE users ALTER COLUMN "email" SET NOT NULL;)

    statement = Avram::Migrator::ChangeNullStatement.new(:users, :email, required: false).build
    statement.should eq %(ALTER TABLE users ALTER COLUMN "email" DROP NOT NULL;)
  end

  it "quotes reserved column names" do
    statement = Avram::Migrator::ChangeNullStatement.new(:users, :from, required: false).build
    statement.should eq %(ALTER TABLE users ALTER COLUMN "from" DROP NOT NULL;)

    statement = Avram::Migrator::ChangeNullStatement.new(:users, :to, required: true).build
    statement.should eq %(ALTER TABLE users ALTER COLUMN "to" SET NOT NULL;)
  end

  it "escapes double quotes in column names" do
    statement = Avram::Migrator::ChangeNullStatement.new(:users, :"some\"column", required: false).build
    statement.should eq %(ALTER TABLE users ALTER COLUMN "some""column" DROP NOT NULL;)
  end
end
