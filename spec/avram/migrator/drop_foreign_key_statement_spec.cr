require "../../spec_helper"

describe Avram::Migrator::DropForeignKeyStatement do
  it "generates correct sql" do
    statement = Avram::Migrator::DropForeignKeyStatement.new(:comments, :users).build
    statement.should eq "ALTER TABLE comments DROP CONSTRAINT comments_user_id_fk;"
  end

  it "generates correct sql with a custom colum" do
    statement = Avram::Migrator::DropForeignKeyStatement.new(:comments, :users, column: :author_id).build
    statement.should eq "ALTER TABLE comments DROP CONSTRAINT comments_author_id_fk;"
  end
end
