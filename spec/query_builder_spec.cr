require "./spec_helper"

describe Avram::QueryBuilder do
  it "ensures uniqueness for where, raw_where, orders, and joins" do
    query = new_query
      .where(Avram::Where::Equal.new(:name, "Paul"))
      .where(Avram::Where::Equal.new(:name, "Paul"))
      .raw_where(Avram::Where::Raw.new("name = ?", "Mikias"))
      .raw_where(Avram::Where::Raw.new("name = ?", "Mikias"))
      .join(Avram::Join::Inner.new(:users, :posts))
      .join(Avram::Join::Inner.new(:users, :posts))
      .order_by(:my_column, :asc)
      .order_by(:my_column, :asc)

    query.wheres.size.should eq(1)
    query.raw_wheres.size.should eq(1)
    query.joins.size.should eq(1)
    query.statement.should eq "SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id WHERE name = $1 AND name = 'Mikias' ORDER BY my_column ASC"
    query.args.should eq ["Paul"]
  end

  it "can reset order" do
    query = new_query.order_by(:my_column, :asc)
    query.statement.should eq "SELECT * FROM users ORDER BY my_column ASC"

    query.reset_order

    query.statement.should eq "SELECT * FROM users"
  end

  it "selects all" do
    new_query.statement.should eq "SELECT * FROM users"
    new_query.args.should eq [] of String
  end

  it "deletes all" do
    new_query.delete.statement.should eq "DELETE FROM users"
  end

  it "deletes where" do
    query = new_query
      .where(Avram::Where::Equal.new(:age, "42"))
      .delete
    query.statement.should eq "DELETE FROM users WHERE age = $1"
    query.args.should eq ["42"]
  end

  it "can be limited" do
    query = new_query.limit(1)
    query.statement.should eq "SELECT * FROM users LIMIT 1"
    query.args.should eq [] of String
  end

  it "can be offset" do
    query = new_query.offset(1)
    query.statement.should eq "SELECT * FROM users OFFSET 1"
    query.args.should eq [] of String
  end

  it "accepts where clauses and limits" do
    query = new_query
      .where(Avram::Where::Equal.new(:name, "Paul"))
      .where(Avram::Where::GreaterThan.new(:age, "20"))
      .where(Avram::Where::Null.new(:nickname))
      .limit(1)
    query.statement.should eq "SELECT * FROM users WHERE name = $1 AND age > $2 AND nickname IS NULL LIMIT 1"
    query.args.should eq ["Paul", "20"]
  end

  it "accepts raw where clauses" do
    query = new_query
      .raw_where(Avram::Where::Raw.new("name = ?", "Mikias"))
      .raw_where(Avram::Where::Raw.new("age > ?", 26))
      .limit(1)
    query.statement.should eq "SELECT * FROM users WHERE name = 'Mikias' AND age > 26 LIMIT 1"
    query.args.empty?.should be_true
  end

  it "can be ordered" do
    query = new_query
      .order_by(:name, :asc)
      .order_by(:birthday, :asc)
      .order_by(:email, :desc)
    query.statement.should eq "SELECT * FROM users ORDER BY name ASC, birthday ASC, email DESC"
    query.args.should eq [] of String

    query = new_query
      .order_by(:name, :asc)
    query.statement.should eq "SELECT * FROM users ORDER BY name ASC"
  end

  it "can select distinct" do
    query = new_query.distinct
    query.statement.should eq "SELECT DISTINCT * FROM users"
    query.args.should eq [] of String
  end

  it "can select distinct on a specific column" do
    query = new_query.distinct_on(:name)
    query.statement.should eq "SELECT DISTINCT ON (name) * FROM users"
    query.args.should eq [] of String
  end

  describe "updating" do
    it "inserts with a hash of String" do
      params = {:first_name => "Paul", :last_name => nil}
      query = Avram::QueryBuilder
        .new(table: :users)
        .where(Avram::Where::Equal.new(:id, "1"))
        .limit(1)

      query.statement_for_update(params).should eq "UPDATE users SET first_name = $1, last_name = $2 WHERE id = $3 LIMIT 1 RETURNING *"
      query.args_for_update(params).should eq ["Paul", nil, "1"]
    end
  end

  it "can be counted" do
    query = Avram::QueryBuilder
      .new(table: :users)
      .select_count

    query.statement.should eq "SELECT COUNT(*) FROM users"
    query.args.should eq [] of String
  end

  it "raises for aggregates with unsupported statements" do
    raises_unsupported_query &.limit(1).select_min(:age)
    raises_unsupported_query &.offset(1).select_min(:age)

    raises_unsupported_query &.limit(1).select_max(:age)
    raises_unsupported_query &.offset(1).select_max(:age)

    raises_unsupported_query &.limit(1).select_sum(:age)
    raises_unsupported_query &.offset(1).select_sum(:age)

    raises_unsupported_query &.limit(1).select_average(:age)
    raises_unsupported_query &.offset(1).select_average(:age)
  end

  it "can get the min" do
    query = Avram::QueryBuilder
      .new(table: :users)
      .select_min(:age)

    query.statement.should eq "SELECT MIN(age) FROM users"
    query.args.should eq [] of String
  end

  it "can get the max" do
    query = Avram::QueryBuilder
      .new(table: :users)
      .select_max(:age)

    query.statement.should eq "SELECT MAX(age) FROM users"
    query.args.should eq [] of String
  end

  it "can get the average" do
    query = Avram::QueryBuilder
      .new(table: :users)
      .select_average(:age)

    query.statement.should eq "SELECT AVG(age) FROM users"
    query.args.should eq [] of String
  end

  it "can sum a column" do
    query = Avram::QueryBuilder
      .new(table: :users)
      .select_sum(:age)

    query.statement.should eq "SELECT SUM(age) FROM users"
    query.args.should eq [] of String
  end

  describe "#select" do
    it "specifies columns to be selected" do
      query = Avram::QueryBuilder
        .new(table: :users)
        .select([:name, :age])

      query.statement.should eq "SELECT users.name, users.age FROM users"
    end
  end

  it "can be joined" do
    query = Avram::QueryBuilder
      .new(table: :users)
      .join(Avram::Join::Inner.new(:users, :posts))
      .limit(1)

    query.statement.should eq "SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id LIMIT 1"
  end

  describe "#reverse_order" do
    it "reverses the order of the query" do
      query = Avram::QueryBuilder
        .new(table: :users)
        .order_by(:id, :asc)
        .reverse_order

      query.statement.should eq "SELECT * FROM users ORDER BY id DESC"
    end

    it "reverses both directions" do
      query = Avram::QueryBuilder
        .new(table: :users)
        .order_by(:id, :asc)
        .order_by(:name, :desc)
        .reverse_order

      query.statement.should eq "SELECT * FROM users ORDER BY name ASC, id DESC"

      TestDatabase.run do |db|
        db.exec query.statement
      end
    end

    it "does nothing if there is no order" do
      query = Avram::QueryBuilder
        .new(table: :users)
        .reverse_order

      query.statement.should eq "SELECT * FROM users"
    end
  end

  describe "#ordered" do
    it "returns true if the query is ordered" do
      query = Avram::QueryBuilder
        .new(table: :users)
        .order_by(:id, :asc)

      query.ordered?.should eq true
    end

    it "returns false if the query is not ordered" do
      query = Avram::QueryBuilder
        .new(table: :users)

      query.ordered?.should eq false
    end
  end

  describe "clone" do
    it "copies over all parts of a query" do
      old_query = new_query
        .select([:name, :age])
        .join(Avram::Join::Inner.new(:users, :posts))
        .where(Avram::Where::Equal.new(:name, "Paul"))
        .order_by(:id, :asc)
        .limit(1)
        .offset(2)
      cloned_query = new_query
        .clone(old_query)
        .where(Avram::Where::GreaterThan.new(:age, "20"))
        .limit(10)
        .offset(5)

      cloned_query.statement.should eq "SELECT users.name, users.age FROM users INNER JOIN posts ON users.id = posts.user_id WHERE name = $1 AND age > $2 ORDER BY id ASC LIMIT 10 OFFSET 5"

      old_query.statement.should eq "SELECT users.name, users.age FROM users INNER JOIN posts ON users.id = posts.user_id WHERE name = $1 ORDER BY id ASC LIMIT 1 OFFSET 2"
    end
  end

  describe "grouped?" do
    it "returns true when there's a grouping" do
      query = Avram::QueryBuilder
        .new(table: :users)
        .group_by(:id)

      query.grouped?.should eq true
    end

    it "returns false when there's no groups" do
      query = Avram::QueryBuilder
        .new(table: :users)

      query.grouped?.should eq false
    end
  end

  describe "group_by" do
    it "groups by a column" do
      query = Avram::QueryBuilder
        .new(table: :users)
        .group_by(:name)

      query.statement.should eq "SELECT * FROM users GROUP BY name"
    end
  end
end

private def new_query
  Avram::QueryBuilder.new(table: :users)
end

private def raises_unsupported_query
  expect_raises Avram::UnsupportedQueryError do
    yield Avram::QueryBuilder.new(table: :users)
  end
end
