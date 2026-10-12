require "../../spec_helper"

private class IndexHelperHarness
  include Avram::Migrator::StatementHelpers

  @table_name : Avram::TableName = :users
  getter prepared_statements = [] of String

  def added_indexes : Array(String)
    index_statements
  end
end

describe Avram::Migrator::StatementHelpers do
  describe "#create_index with a partial-index where:" do
    it "passes a raw String predicate straight through via where_raw" do
      helper = IndexHelperHarness.new
      helper.create_index(:users, :email, where_raw: "email IS NOT NULL")
      helper.prepared_statements.last.should eq %(CREATE INDEX users_email_index ON users USING btree ("email") WHERE email IS NOT NULL;)
    end

    it "raises when given both where: and where_raw:" do
      helper = IndexHelperHarness.new
      expect_raises(ArgumentError) do
        helper.create_index(:users, :name, where: UserQuery.new.age(18), where_raw: "age = 18")
      end
    end

    it "inlines an Avram::Queryable's where conditions as literals" do
      helper = IndexHelperHarness.new
      helper.create_index(:users, :name, unique: true, where: UserQuery.new.age(18))
      helper.prepared_statements.last.should eq %(CREATE UNIQUE INDEX users_name_index ON users USING btree ("name") WHERE "users"."age" = '18';)
    end

    it "single-quotes boolean values inlined from a query" do
      helper = IndexHelperHarness.new
      helper.create_index(:users, :name, where: UserQuery.new.available_for_hire(true))
      helper.prepared_statements.last.should eq %(CREATE INDEX users_name_index ON users USING btree ("name") WHERE "users"."available_for_hire" = 'true';)
    end

    it "keeps OR conjunctions and drops order_by/limit from the predicate" do
      query = UserQuery.new.age(18).or(&.name("Paul")).order_by(:name, :asc).limit(5)
      helper = IndexHelperHarness.new
      helper.create_index(:users, :name, where: query)
      helper.prepared_statements.last.should eq %(CREATE INDEX users_name_index ON users USING btree ("name") WHERE "users"."age" = '18' OR "users"."name" = 'Paul';)
    end

    it "composes where: with a custom index name" do
      helper = IndexHelperHarness.new
      helper.create_index(:users, :email, name: "active_email_idx", where: UserQuery.new.available_for_hire(true))
      helper.prepared_statements.last.should eq %(CREATE INDEX active_email_idx ON users USING btree ("email") WHERE "users"."available_for_hire" = 'true';)
    end

    it "raises when given a query with no where conditions" do
      helper = IndexHelperHarness.new
      expect_raises(Avram::InvalidQueryError) do
        helper.create_index(:users, :name, where: UserQuery.new)
      end
    end
  end
end

describe Avram::Migrator::IndexStatementHelpers do
  describe "#add_index with a partial-index where:" do
    it "passes a raw String predicate straight through via where_raw" do
      helper = IndexHelperHarness.new
      helper.add_index(:email, where_raw: "email IS NOT NULL")
      helper.added_indexes.last.should eq %(CREATE INDEX users_email_index ON users USING btree ("email") WHERE email IS NOT NULL;)
    end

    it "inlines an Avram::Queryable's where conditions for a unique index" do
      helper = IndexHelperHarness.new
      helper.add_index(:age, unique: true, where: UserQuery.new.age(18))
      helper.added_indexes.last.should eq %(CREATE UNIQUE INDEX users_age_index ON users USING btree ("age") WHERE "users"."age" = '18';)
    end
  end
end
