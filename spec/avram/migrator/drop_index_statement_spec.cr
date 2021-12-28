require "../../spec_helper"

describe Avram::Migrator::DropIndexStatement do
  it "generates correct sql for single column" do
    statement = Avram::Migrator::DropIndexStatement.new(:users, :email, on_delete: :cascade, if_exists: true).build
    statement.should eq "DROP INDEX IF EXISTS users_email_index CASCADE;"
  end

  it "generates correct sql for multiple columns" do
    statement = Avram::Migrator::DropIndexStatement.new(:users, [:email, :username], on_delete: :cascade, if_exists: true).build
    statement.should eq "DROP INDEX IF EXISTS users_email_username_index CASCADE;"
  end

  context "custom index name" do
    it "generates correct sql with given name" do
      statement = Avram::Migrator::DropIndexStatement.new(:users, name: :custom_index_name).build
      statement.should eq "DROP INDEX custom_index_name;"
    end
  end

  context "without name and columns" do
    it "raises Exception" do
      message = Regex.new("No name or columns specified for drop_index")
      expect_raises(Exception, message) do
        Avram::Migrator::DropIndexStatement.new(:users).build
      end
    end
  end
end
