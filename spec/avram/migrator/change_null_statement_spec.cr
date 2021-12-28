require "../../spec_helper"

describe Avram::Migrator::ChangeNullStatement do
  it "generates correct sql" do
    statement = Avram::Migrator::ChangeNullStatement.new(:users, :email, required: true).build
    statement.should eq "ALTER TABLE users ALTER COLUMN email SET NOT NULL;"

    statement = Avram::Migrator::ChangeNullStatement.new(:users, :email, required: false).build
    statement.should eq "ALTER TABLE users ALTER COLUMN email DROP NOT NULL;"
  end
end
