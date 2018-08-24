require "../spec_helper"

describe LuckyRecord::Migrator::CreateIndexStatement do
  it "generates correct CREATE INDEX sql" do
    statement = LuckyRecord::Migrator::CreateIndexStatement.new(:users, :email).build
    statement.should eq "CREATE INDEX users_email_index ON users USING btree (email);"

    statement = LuckyRecord::Migrator::CreateIndexStatement.new(:users, columns: :email, using: :btree, unique: true).build
    statement.should eq "CREATE UNIQUE INDEX users_email_index ON users USING btree (email);"
  end

  it "generates correct multi-column index sql" do
    statement = LuckyRecord::Migrator::CreateIndexStatement.new(:users, columns: [:email, :username], using: :btree, unique: true).build
    statement.should eq "CREATE UNIQUE INDEX users_email_username_index ON users USING btree (email, username);"
  end
end
