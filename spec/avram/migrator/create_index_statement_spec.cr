require "../../spec_helper"

describe Avram::Migrator::CreateIndexStatement do
  it "generates correct CREATE INDEX sql" do
    statement = Avram::Migrator::CreateIndexStatement.new(:users, :email).build
    statement.should eq %(CREATE INDEX users_email_index ON users USING btree ("email");)

    statement = Avram::Migrator::CreateIndexStatement.new(:users, columns: :email, using: :btree, unique: true).build
    statement.should eq %(CREATE UNIQUE INDEX users_email_index ON users USING btree ("email");)

    statement = Avram::Migrator::CreateIndexStatement.new(:users, columns: :email, using: :btree, concurrently: true).build
    statement.should eq %(CREATE INDEX CONCURRENTLY users_email_index ON users USING btree ("email");)
  end

  it "supports other index types" do
    statement = Avram::Migrator::CreateIndexStatement.new(:users, columns: :tags, using: :hash).build
    statement.should eq %(CREATE INDEX users_tags_index ON users USING hash ("tags");)

    statement = Avram::Migrator::CreateIndexStatement.new(:users, columns: :tags, using: :gist).build
    statement.should eq %(CREATE INDEX users_tags_index ON users USING gist ("tags");)

    statement = Avram::Migrator::CreateIndexStatement.new(:users, columns: :tags, using: :gin).build
    statement.should eq %(CREATE INDEX users_tags_index ON users USING gin ("tags");)

    statement = Avram::Migrator::CreateIndexStatement.new(:users, columns: :tags, using: :brin).build
    statement.should eq %(CREATE INDEX users_tags_index ON users USING brin ("tags");)
  end

  it "generates correct multi-column index sql" do
    statement = Avram::Migrator::CreateIndexStatement.new(:users, columns: [:email, :username], using: :btree, unique: true).build
    statement.should eq %(CREATE UNIQUE INDEX users_email_username_index ON users USING btree ("email", "username");)
  end

  context "custom index name" do
    it "generates correct CREATE INDEX sql with given name" do
      statement = Avram::Migrator::CreateIndexStatement.new(:users, :email, name: :custom_index_name).build
      statement.should eq %(CREATE INDEX custom_index_name ON users USING btree ("email");)
    end
  end

  context "partial index with a WHERE clause" do
    it "appends the predicate after the column list" do
      statement = Avram::Migrator::CreateIndexStatement.new(:users, :email, where: "email IS NOT NULL").build
      statement.should eq %(CREATE INDEX users_email_index ON users USING btree ("email") WHERE email IS NOT NULL;)
    end

    it "generates a conditional UNIQUE partial index" do
      statement = Avram::Migrator::CreateIndexStatement.new(:servers, columns: [:col_a, :col_b, :col_c], unique: true, where: "col_d >= 5").build
      statement.should eq %(CREATE UNIQUE INDEX servers_col_a_col_b_col_c_index ON servers USING btree ("col_a", "col_b", "col_c") WHERE col_d >= 5;)
    end

    it "composes with CONCURRENTLY" do
      statement = Avram::Migrator::CreateIndexStatement.new(:users, :email, concurrently: true, where: "email IS NOT NULL").build
      statement.should eq %(CREATE INDEX CONCURRENTLY users_email_index ON users USING btree ("email") WHERE email IS NOT NULL;)
    end
  end
end
