require "../spec_helper"

describe LuckyRecord::Migrator::DropIndexStatement do
  it "generates correct sql for single column" do
    statement = LuckyRecord::Migrator::DropIndexStatement.new(:users, :email, on_delete: :cascade, if_exists: true).build
    statement.should eq "DROP INDEX IF EXISTS users_email_index CASCADE;"
  end

  it "generates correct sql for multiple columns" do
    statement = LuckyRecord::Migrator::DropIndexStatement.new(:users, [:email, :username], on_delete: :cascade, if_exists: true).build
    statement.should eq "DROP INDEX IF EXISTS users_email_username_index CASCADE;"
  end
end
