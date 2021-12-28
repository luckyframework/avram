require "../../spec_helper"

describe Avram::Migrator::CreateForeignKeyStatement do
  it "generates correct sql with cascade strategy" do
    statement = Avram::Migrator::CreateForeignKeyStatement.new(:comments, :users, column: :author_id, on_delete: :cascade, primary_key: :uid).build
    statement.should eq "ALTER TABLE comments ADD CONSTRAINT comments_author_id_fk FOREIGN KEY (author_id) REFERENCES users (uid) ON DELETE CASCADE;"
  end

  it "generates correct sql with nullify strategy" do
    statement = Avram::Migrator::CreateForeignKeyStatement.new(:comments, :users, column: :author_id, on_delete: :nullify, primary_key: :uid).build
    statement.should eq "ALTER TABLE comments ADD CONSTRAINT comments_author_id_fk FOREIGN KEY (author_id) REFERENCES users (uid) ON DELETE SET NULL;"
  end

  it "raises error on invalid on_delete strategy" do
    expect_raises Exception, "on_delete: :cascad is not supported. Please use :do_nothing, :cascade, :restrict, or :nullify" do
      Avram::Migrator::CreateForeignKeyStatement.new(:comments, :users, on_delete: :cascad).build
    end
  end
end
