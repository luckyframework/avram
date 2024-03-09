require "../../spec_helper"

describe Avram::Migrator::CreateSequenceStatement do
  it "generates correct CREATE SEQUENCE sql" do
    statement = Avram::Migrator::CreateSequenceStatement.new(:accounts_number).build
    statement.should eq "CREATE SEQUENCE accounts_number_seq OWNED BY NONE;"

    statement = Avram::Migrator::CreateSequenceStatement.new(:accounts_number, if_not_exists: true).build
    statement.should eq "CREATE SEQUENCE IF NOT EXISTS accounts_number_seq OWNED BY NONE;"

    statement = Avram::Migrator::CreateSequenceStatement.new(:accounts_number, owned_by: "accounts.number").build
    statement.should eq "CREATE SEQUENCE accounts_number_seq OWNED BY accounts.number;"
  end
end
