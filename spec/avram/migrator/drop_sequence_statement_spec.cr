require "../../spec_helper"

describe Avram::Migrator::DropSequenceStatement do
  it "generates correct DROP SEQUENCE sql" do
    statement = Avram::Migrator::DropSequenceStatement.new(:accounts_number).build
    statement.should eq "DROP SEQUENCE IF EXISTS accounts_number_seq;"
  end
end
