require "../spec_helper"

describe Avram::QueryBuilder do
  it "ensures uniqueness for orders, and joins" do
    query = new_query
      .join(Avram::Join::Inner.new(:users, :posts))
      .join(Avram::Join::Inner.new(:users, :posts))
      .order_by(Avram::OrderBy.new(:my_column, :asc))
      .order_by(Avram::OrderBy.new(:my_column, :asc))

    query.joins.size.should eq(1)
    query.statement.should eq "SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id ORDER BY my_column ASC"
  end

  it "does not remove potentially duplicate where clauses" do
    query = new_query
      .where(Avram::Where::Equal.new(:name, "Paul"))
      .where(Avram::Where::Equal.new(:age, "18"))
      .or(&.where(Avram::Where::Equal.new(:name, "Paul"))
        .where(Avram::Where::Equal.new(:age, "100")))

    query.statement.should eq "SELECT * FROM users WHERE name = $1 AND age = $2 OR name = $3 AND age = $4"
  end

  it "can reset order" do
    query = new_query.order_by(Avram::OrderBy.new(:my_column, :asc))
    query.statement.should eq "SELECT * FROM users ORDER BY my_column ASC"

    query.reset_order

    query.statement.should eq "SELECT * FROM users"
  end

  it "can reset where for a specific column" do
    query = new_query
      .where(Avram::Where::GreaterThan.new(:age, "18"))
      .where(Avram::Where::LessThan.new(:age, "81"))
      .where(Avram::Where::Equal.new(:name, "Pauline"))
    query.args.should eq ["18", "81", "Pauline"]

    query.reset_where("name")

    query.statement.should eq "SELECT * FROM users WHERE age > $1 AND age < $2"
    query.args.should eq ["18", "81"]

    query.reset_where(:age)

    query.args.should be_empty
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

  it "has the same statement on subsequent calls" do
    query = new_query
      .where(Avram::Where::Equal.new(:name, "Paul"))
      .where(Avram::Where::GreaterThan.new(:age, "20"))
    query.statement.should eq "SELECT * FROM users WHERE name = $1 AND age > $2"
    query.statement.should eq "SELECT * FROM users WHERE name = $1 AND age > $2"
  end

  it "accepts raw where clauses" do
    query = new_query
      .where(Avram::Where::Raw.new("name = ?", "Mikias"))
      .where(Avram::Where::Raw.new("age > ?", 26))
      .where(Avram::Where::Raw.new("age < ?", args: [30]))
      .limit(1)
    query.statement.should eq "SELECT * FROM users WHERE name = 'Mikias' AND age > 26 AND age < 30 LIMIT 1"
    query.args.empty?.should be_true
  end

  it "can be ordered" do
    query = new_query
      .order_by(Avram::OrderBy.new(:name, :asc))
      .order_by(Avram::OrderBy.new(:birthday, :asc))
      .order_by(Avram::OrderBy.new(:email, :desc))
    query.statement.should eq "SELECT * FROM users ORDER BY name ASC, birthday ASC, email DESC"
    query.args.should eq [] of String

    query = new_query
      .order_by(Avram::OrderBy.new(:name, :asc))
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
      query = new_query
        .where(Avram::Where::Equal.new(:id, "1"))
        .limit(1)

      query.statement_for_update(params).should eq "UPDATE users SET first_name = $1, last_name = $2 WHERE id = $3 LIMIT 1 RETURNING *"
      query.args_for_update(params).should eq ["Paul", nil, "1"]
    end

    it "has the same placeholder values on subsequent calls" do
      params = {:first_name => "Paul", :last_name => nil}
      query = new_query
        .where(Avram::Where::Equal.new(:id, "1"))
        .limit(1)

      query.statement_for_update(params).should eq "UPDATE users SET first_name = $1, last_name = $2 WHERE id = $3 LIMIT 1 RETURNING *"
      query.statement_for_update(params).should eq "UPDATE users SET first_name = $1, last_name = $2 WHERE id = $3 LIMIT 1 RETURNING *"
    end
  end

  it "can be counted" do
    query = new_query.select_count

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
    query = new_query.select_min(:age)

    query.statement.should eq "SELECT MIN(age) FROM users"
    query.args.should eq [] of String
  end

  it "can get the max" do
    query = new_query.select_max(:age)

    query.statement.should eq "SELECT MAX(age) FROM users"
    query.args.should eq [] of String
  end

  it "can get the average" do
    query = new_query.select_average(:age)

    query.statement.should eq "SELECT AVG(age) FROM users"
    query.args.should eq [] of String
  end

  it "can sum a column" do
    query = new_query.select_sum(:age)

    query.statement.should eq "SELECT SUM(age) FROM users"
    query.args.should eq [] of String
  end

  describe "#select" do
    it "specifies columns to be selected" do
      query = new_query.select([:name, :age])

      query.statement.should eq "SELECT users.name, users.age FROM users"
    end
  end

  it "can be joined" do
    query = new_query
      .join(Avram::Join::Inner.new(:users, :posts))
      .limit(1)

    query.statement.should eq "SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id LIMIT 1"
  end

  describe "#reverse_order" do
    it "reverses the order of the query" do
      query = new_query
        .order_by(Avram::OrderBy.new(:id, :asc))
        .reverse_order

      query.statement.should eq "SELECT * FROM users ORDER BY id DESC"
    end

    it "reverses both directions" do
      query = new_query
        .order_by(Avram::OrderBy.new(:id, :asc))
        .order_by(Avram::OrderBy.new(:name, :desc))
        .reverse_order

      query.statement.should eq "SELECT * FROM users ORDER BY name ASC, id DESC"

      TestDatabase.run do |db|
        db.exec query.statement
      end
    end

    it "does nothing if there is no order" do
      query = new_query.reverse_order

      query.statement.should eq "SELECT * FROM users"
    end
  end

  describe "#ordered" do
    it "returns true if the query is ordered" do
      query = new_query
        .order_by(Avram::OrderBy.new(:id, :asc))

      query.ordered?.should eq true
    end

    it "returns false if the query is not ordered" do
      query = new_query

      query.ordered?.should eq false
    end
  end

  describe "clone" do
    it "copies over all parts of a query" do
      old_query = new_query
        .select([:name, :age])
        .join(Avram::Join::Inner.new(:users, :posts))
        .where(Avram::Where::Equal.new(:name, "Paul"))
        .order_by(Avram::OrderBy.new(:id, :asc))
        .limit(1)
        .offset(2)
      cloned_query = old_query
        .clone
        .where(Avram::Where::GreaterThan.new(:age, "20"))
        .limit(10)
        .offset(5)

      cloned_query.statement.should eq "SELECT users.name, users.age FROM users INNER JOIN posts ON users.id = posts.user_id WHERE name = $1 AND age > $2 ORDER BY id ASC LIMIT 10 OFFSET 5"

      old_query.statement.should eq "SELECT users.name, users.age FROM users INNER JOIN posts ON users.id = posts.user_id WHERE name = $1 ORDER BY id ASC LIMIT 1 OFFSET 2"
    end
  end

  describe "grouped?" do
    it "returns true when there's a grouping" do
      query = new_query.group_by(:id)

      query.grouped?.should eq true
    end

    it "returns false when there's no groups" do
      query = new_query

      query.grouped?.should eq false
    end
  end

  describe "group_by" do
    it "groups by a column" do
      query = new_query
        .group_by(:name)

      query.statement.should eq "SELECT * FROM users GROUP BY name"
    end

    it "groups by multiple columns" do
      query = new_query
        .group_by(:age)
        .group_by(:average_score)
      query.statement.should eq "SELECT * FROM users GROUP BY age, average_score"
    end

    it "groups in the proper order with other query parts" do
      query = new_query
        .where(Avram::Where::Equal.new(:name, "Paul"))
        .order_by(Avram::OrderBy.new(:name, :desc))
        .group_by(:age)
        .group_by(:average_score)
        .limit(10)
      query.statement.should eq "SELECT * FROM users WHERE name = $1 GROUP BY age, average_score ORDER BY name DESC LIMIT 10"
      query.args.should eq ["Paul"]
    end
  end

  describe "#or" do
    it "builds the proper SQL for a simple OR query" do
      query = new_query
        .where(Avram::Where::Equal.new(:name, "Paul"))
        .or(&.where(Avram::Where::Equal.new(:name, "Peter")))

      query.statement.should eq "SELECT * FROM users WHERE name = $1 OR name = $2"
      query.args.should eq ["Paul", "Peter"]
    end

    it "raises an excception when called without a previous where clause" do
      expect_raises(Avram::InvalidQueryError, "Cannot call `or` before calling a `where`") do
        new_query.or(&.where(Avram::Where::Equal.new(:name, "Peter")))
      end
    end
  end
end

private def new_query
  Avram::QueryBuilder.new(table: :users)
end

private def raises_unsupported_query(&)
  expect_raises Avram::UnsupportedQueryError do
    yield Avram::QueryBuilder.new(table: :users)
  end
end
