require "../spec_helper"

class ChainedQuery < User::BaseQuery
  def young
    age.lte(18)
  end

  def named(value)
    name(value)
  end
end

class JSONQuery < Blob::BaseQuery
  def static_foo
    doc(JSON::Any.new({"foo" => JSON::Any.new("bar")}))
  end

  def foo_with_value(value : String)
    doc(JSON::Any.new({"foo" => JSON::Any.new(value)}))
  end
end

class QueryWithDefault < User::BaseQuery
  def initialize
    defaults &.age.gte(21)
  end
end

class CommentQuery < Comment::BaseQuery
end

class PostQuery < Post::BaseQuery
end

class CachedUserQuery < User::BaseQuery
  class_property query_counter : Int32 = 0

  private def exec_query
    @@query_counter += 1
    super
  end
end

describe Avram::Queryable do
  Spec.before_each do
    CachedUserQuery.query_counter = 0
  end

  it "can chain scope methods" do
    ChainedQuery.new.young.named("Paul")
  end

  it "can set default queries" do
    query = QueryWithDefault.new.query

    query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE users.age >= $1"
  end

  it "allows you to add on to a query with default" do
    query = QueryWithDefault.new.name("Santa").query

    query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE users.age >= $1 AND users.name = $2"
  end

  it "releases connection if no open transaction", tags: Avram::SpecHelper::TRUNCATE do
    UserQuery.new.first?

    TestDatabase.connections.should be_empty
  end

  describe "#distinct" do
    it "selects distinct" do
      query = UserQuery.new.distinct.query

      query.statement.should eq "SELECT DISTINCT #{User::COLUMN_SQL} FROM users"
      query.args.should eq [] of String
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.distinct

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#reset_order" do
    it "resets the order" do
      query = UserQuery.new.order_by(:some_column, :asc).reset_order.query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users"
      query.args.should eq [] of String
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.order_by(:name, :asc)
      original_query_sql = query.to_sql

      query.reset_order

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#reset_where" do
    it "resets where on a specific column" do
      query = UserQuery.new.name("Purcell").age(35).reset_where(&.name).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE users.age = $1"
      query.args.should eq ["35"] of String
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name").age(35)
      original_query_sql = query.to_sql

      query.reset_where(&.name)

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#distinct_on" do
    it "selects distinct on a specific column" do
      UserFactory.new.name("Purcell").age(22).create
      UserFactory.new.name("Purcell").age(84).create
      UserFactory.new.name("Griffiths").age(55).create
      UserFactory.new.name("Griffiths").age(75).create
      queryable = UserQuery.new.distinct_on(&.name).order_by(:name, :asc).order_by(:age, :asc)
      query = queryable.query

      query.statement.should eq "SELECT DISTINCT ON (users.name) #{User::COLUMN_SQL} FROM users ORDER BY name ASC, age ASC"
      query.args.should eq [] of String
      results = queryable.results
      first = results.first
      second = results.last
      first.name.should eq "Griffiths"
      first.age.should eq 55
      second.name.should eq "Purcell"
      second.age.should eq 22
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.distinct_on(&.name)

      query.to_sql.should eq original_query_sql
    end
  end

  describe ".first" do
    it "gets the first row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      UserQuery.first.name.should eq "First"
    end

    it "raises RecordNotFound if no record is found" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.first
      end
    end
  end

  describe "#first" do
    it "gets the first row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      UserQuery.new.first.name.should eq "First"
    end

    it "raises RecordNotFound if no record is found" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.new.first
      end
    end
  end

  describe ".first?" do
    it "gets the first row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      user = UserQuery.first?
      user.should_not be_nil
      user.as(User).name.should eq "First"
    end

    it "returns nil if no record found" do
      UserQuery.first?.should be_nil
    end
  end

  describe "#first?" do
    it "gets the first row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      user = UserQuery.new.first?
      user_query = Avram::Events::QueryEvent.logged_events.last.query

      user.should_not be_nil
      user.as(User).name.should eq "First"
      user_query.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY users.id ASC LIMIT 1"
    end

    it "returns nil if no record found" do
      UserQuery.new.first?.should be_nil
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.first?

      query.to_sql.should eq original_query_sql
    end
  end

  describe ".last" do
    it "gets the last row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      UserQuery.last.name.should eq "Last"
    end

    it "raises RecordNotFound if no record is found" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.last
      end
    end
  end

  describe "#last" do
    it "gets the last row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      UserQuery.new.last.name.should eq "Last"
    end

    it "reverses the order of ordered queries" do
      UserFactory.new.name("Alpha").create
      UserFactory.new.name("Charlie").create
      UserFactory.new.name("Bravo").create

      UserQuery.new.order_by(:name, :desc).last.name.should eq "Alpha"
    end

    it "raises RecordNotFound if no record is found" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.new.last
      end
    end
  end

  describe ".last?" do
    it "gets the last row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      user = UserQuery.last?

      user.should_not be_nil
      user.as(User).name.should eq "Last"
    end

    it "returns nil if last record is not found" do
      UserQuery.last?.should be_nil
    end

    it "allows queries with random order" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      user = UserQuery.new.random_order.last?
      user_query = Avram::Events::QueryEvent.logged_events.last.query

      user.should_not be_nil
      user_query.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY RANDOM () LIMIT 1"
    end
  end

  describe "#last?" do
    it "gets the last row from the database" do
      UserFactory.new.name("First").create
      UserFactory.new.name("Last").create

      user = UserQuery.new.last?
      user_query = Avram::Events::QueryEvent.logged_events.last.query

      user.should_not be_nil
      user.as(User).name.should eq "Last"
      user_query.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY users.id DESC LIMIT 1"
    end

    it "returns nil if last record is not found" do
      UserQuery.new.last?.should be_nil
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.last?

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#any?" do
    it "is true if there is a record in the database" do
      UserFactory.new.name("First").create

      UserQuery.new.name("First").any?.should be_true # ameba:disable Performance/AnyInsteadOfEmpty
    end

    it "is false if there is not a record in the database" do
      UserFactory.new.name("First").create

      UserQuery.new.name("Second").any?.should be_false # ameba:disable Performance/AnyInsteadOfEmpty
    end

    it "does not mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.any? # ameba:disable Performance/AnyInsteadOfEmpty

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#none?" do
    it "is true if no records found in database" do
      UserFactory.new.name("First").create

      UserQuery.new.name("Second").none?.should be_true
    end

    it "is false if there is a record in the database" do
      UserFactory.new.name("First").create

      UserQuery.new.name("First").none?.should be_false
    end
  end

  describe ".find" do
    it "gets the record with the given id" do
      UserFactory.create
      user = UserQuery.first

      UserQuery.find(user.id).should eq user
    end

    it "raises RecordNotFound if no record is found with the given id (Int32)" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.find(1)
      end
    end

    it "raises RecordNotFound if no record is found with the given id (String)" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.find("1")
      end
    end

    it "raises PQ::PQError if no record is found with letter-only id (String)" do
      expect_raises(Exception, "FailedCast") do
        UserQuery.find("id")
      end
    end
  end

  describe "#find" do
    it "gets the record with the given id" do
      UserFactory.create
      user = UserQuery.new.first

      UserQuery.new.find(user.id).should eq user
    end

    it "raises RecordNotFound if no record is found with the given id (Int32)" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.new.find(1)
      end
    end

    it "raises RecordNotFound if no record is found with the given id (String)" do
      expect_raises(Avram::RecordNotFoundError) do
        UserQuery.new.find("1")
      end
    end

    it "raises PQ::PQError if no record is found with letter-only id (String)" do
      expect_raises(Exception, "FailedCast") do
        UserQuery.new.find("id")
      end
    end

    it "doesn't mutate the query" do
      user = UserFactory.new.create
      query = UserQuery.new
      original_query_sql = query.to_sql

      query.find(user.id)

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#where" do
    it "chains wheres" do
      query = UserQuery.new.where(:first_name, "Paul").where(:last_name, "Smith").query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE first_name = $1 AND last_name = $2"
      query.args.should eq ["Paul", "Smith"]
    end

    it "handles int" do
      query = UserQuery.new.where(:id, 1).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE id = $1"
      query.args.should eq ["1"]
    end

    it "accepts raw sql with bindings and chains with itself" do
      user = UserFactory.new.name("Mikias Abera").age(26).nickname("miki").create
      users = UserQuery.new.where("name = ? AND age = ?", "Mikias Abera", 26).where(:nickname, "miki")

      users.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE name = 'Mikias Abera' AND age = 26 AND nickname = $1"

      users.query.args.should eq ["miki"]
      users.results.should eq [user]
    end

    it "raises when number of bind variables don't match bindings" do
      expect_raises Exception, "wrong number of bind variables (2 for 1)" do
        UserQuery.new.where("name = ?", "bound", "extra")
      end
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.where(:first_name, "Paul")
      original_query_sql = query.to_sql

      query.where(:last_name, "Smith")

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#or" do
    it "chains ors" do
      query = UserQuery.new.age(26).or(&.age(32)).or(&.age(59)).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE users.age = $1 OR users.age = $2 OR users.age = $3"
      query.args.should eq ["26", "32", "59"]
    end

    it "nests AND conjunctions inside of OR blocks" do
      query = UserQuery.new.age(26).or(&.age(32).name("Pat")).or(&.age(59)).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE users.age = $1 OR users.age = $2 AND users.name = $3 OR users.age = $4"
      query.args.should eq ["26", "32", "Pat", "59"]
    end
  end

  describe "#where with block" do
    it "wraps a simple where clause with parenthesis" do
      query = UserQuery.new.where(&.age(30)).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE ( users.age = $1 )"
      query.args.should eq ["30"]
    end

    it "wraps complex queries" do
      query = UserQuery.new.where { |user_q|
        user_q.where { |q|
          q.age(25).or(&.age(26))
        }.where { |q|
          q.name("Billy").or(&.name("Tommy"))
        }
      }.or { |q|
        q.nickname("Strange")
      }.query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE ( ( users.age = $1 OR users.age = $2 ) AND ( users.name = $3 OR users.name = $4 ) ) OR users.nickname = $5"
      query.args.should eq ["25", "26", "Billy", "Tommy", "Strange"]
    end

    it "clones properly when assigned to a variable and updated later" do
      orig_query = UserQuery.new

      new_query = orig_query.where(&.nickname("BusyCat")).limit(3)

      orig_query.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users"
      new_query.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE ( users.nickname = $1 ) LIMIT 3"
    end

    it "doesn't add parenthesis when query to wrap is provided" do
      query = UserQuery.new.name("Susan").where do |q|
        some_condition = false
        if some_condition
          q.name("john")
        else
          q
        end
      end.age(25).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE users.name = $1 AND users.age = $2"
      query.args.should eq ["Susan", "25"]
    end
  end

  describe "#limit" do
    it "adds a limit clause" do
      queryable = UserQuery.new.limit(2)

      queryable.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users LIMIT 2"
    end

    it "works while chaining" do
      UserFactory.create
      UserFactory.create
      users = UserQuery.new.name.desc_order.limit(1)

      users.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY users.name DESC LIMIT 1"

      users.results.size.should eq(1)
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.limit(2)

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#offset" do
    it "adds an offset clause" do
      query = UserQuery.new.offset(2).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users OFFSET 2"
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.offset(2)

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#order_by" do
    it "adds an order clause" do
      query = UserQuery.new.order_by(:name, :asc).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY name ASC"
    end

    it "returns a nice error when trying to order by a weird direction" do
      expect_raises(Exception, /Accepted values are: :asc, :desc/) do
        Post::BaseQuery.new.order_by(:published_at, :sideways)
      end
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.order_by(:name, :asc)

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#none" do
    it "returns 0 records" do
      UserFactory.create

      query = UserQuery.new.none

      query.results.size.should eq 0
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.none

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#select_min" do
    it "returns the minimum" do
      UserFactory.create &.age(2)
      UserFactory.create &.age(1)
      UserFactory.create &.age(3)
      min = UserQuery.new.age.select_min
      min.should eq 1
    end

    it "works with chained where clauses" do
      UserFactory.create &.age(2)
      UserFactory.create &.age(1)
      UserFactory.create &.age(3)
      min = UserQuery.new.age.gte(2).age.select_min
      min.should eq 2
    end

    it "returns nil if no records" do
      min = UserQuery.new.age.select_min
      min.should be_nil
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.age.select_min

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#select_max" do
    it "returns the maximum" do
      UserFactory.create &.age(2)
      UserFactory.create &.age(1)
      UserFactory.create &.age(3)
      max = UserQuery.new.age.select_max
      max.should eq 3
    end

    it "works with chained where clauses" do
      UserFactory.create &.age(2)
      UserFactory.create &.age(1)
      UserFactory.create &.age(3)
      max = UserQuery.new.age.lte(2).age.select_max
      max.should eq 2
    end

    it "returns nil if no records" do
      max = UserQuery.new.age.select_max
      max.should be_nil
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.age.select_max

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#select_average" do
    it "returns the average" do
      UserFactory.create &.age(2)
      UserFactory.create &.age(1)
      UserFactory.create &.age(3)
      average = UserQuery.new.age.select_average
      average.should eq 2
      average.should be_a Float64
    end

    it "returns nil if there are no records" do
      average = UserQuery.new.age.select_average
      average.should be_nil
    end

    it "works with chained where clauses" do
      UserFactory.create &.age(2)
      UserFactory.create &.age(1)
      UserFactory.create &.age(3)
      average = UserQuery.new.age.gte(2).age.select_average
      average.should eq 2.5
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.age.select_average

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#select_average!" do
    it "returns 0_f64 if there are no records" do
      average = UserQuery.new.age.select_average!
      average.should eq 0
      average.should be_a Float64
    end
  end

  describe "#select_sum" do
    it "works with chained where clauses" do
      UserFactory.create &.total_score(2000)
      UserFactory.create &.total_score(1000)
      UserFactory.create &.total_score(3000)
      sum = UserQuery.new.total_score.gte(2000).total_score.select_sum
      sum.should eq 5000
    end

    it "returns nil if there are no records" do
      query_sum = UserQuery.new.age.select_sum
      query_sum.should be_nil
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.total_score.select_sum

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#select_sum for Int64 column" do
    it "returns the sum" do
      UserFactory.create &.total_score(2000)
      UserFactory.create &.total_score(1000)
      UserFactory.create &.total_score(3000)
      sum = UserQuery.new.total_score.select_sum
      sum.should eq 6000
      sum.should be_a Int64
    end
  end

  describe "#select_sum! for Int64 column" do
    it "returns 0 if there are no records" do
      query_sum = UserQuery.new.total_score.select_sum!
      query_sum.should eq 0
      query_sum.should be_a Int64
    end
  end

  describe "#select_sum for Int32 column" do
    it "returns the sum" do
      UserFactory.create &.age(2)
      UserFactory.create &.age(1)
      UserFactory.create &.age(3)
      query_sum = UserQuery.new.age.select_sum
      query_sum.should eq 6
      query_sum.should be_a Int64
    end
  end

  describe "#select_sum! for Int32 column" do
    it "returns 0 if there are no records" do
      query_sum = UserQuery.new.id.select_sum!
      query_sum.should eq 0
      query_sum.should be_a Int64
    end
  end

  describe "#select_sum for Int16 column" do
    it "returns the sum" do
      UserFactory.create &.year_born(1990_i16)
      UserFactory.create &.year_born(1995_i16)
      query_sum = UserQuery.new.year_born.select_sum
      query_sum.should eq 3985
      query_sum.should be_a Int64
    end
  end

  describe "#select_sum! for Int16 column" do
    it "returns 0 if there are no records" do
      query_sum = UserQuery.new.id.select_sum!
      query_sum.should eq 0
      query_sum.should be_a Int64
    end
  end

  describe "#select_sum for Float64 column" do
    it "returns the sum" do
      scores = [100.4, 123.22]
      sum = scores.sum
      scores.each { |score| UserFactory.create &.average_score(score) }
      query_sum = UserQuery.new.average_score.select_sum
      query_sum.should eq sum
      sum.should be_a Float64
    end
  end

  describe "#select_sum! for Float64 column" do
    it "returns 0 if there are no records" do
      query_sum = UserQuery.new.average_score.select_sum!
      query_sum.should eq 0
      query_sum.should be_a Float64
    end
  end

  describe "#select_count" do
    it "returns the number of database rows" do
      count = UserQuery.new.select_count
      count.should eq 0

      UserFactory.create
      count = UserQuery.new.select_count
      count.should eq 1
    end

    it "works with ORDER BY by removing the ordering" do
      UserFactory.create

      query = UserQuery.new.name.desc_order

      query.select_count.should eq 1
    end

    it "works with chained where" do
      UserFactory.new.age(30).create
      UserFactory.new.age(31).create

      query = UserQuery.new.age.gte(31)

      query.select_count.should eq 1
    end

    it "works with distinct_on" do
      UserFactory.new.age(30).create
      UserFactory.new.age(30).create

      query = UserQuery.new.distinct_on(&.age)

      query.select_count.should eq 1
    end

    it "returns 0 if postgres returns no results" do
      query = UserQuery.new.distinct_on(&.name).average_score.gt(5).group(&.name).group(&.id).select_count
      query.should eq 0
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.select_count

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#group_count" do
    context "when no records exist" do
      it "0 grouped columns returns { [] => 0 }" do
        query = UserQuery.new

        query.group_count.should eq({[] of String => 0})
      end

      # Return an empty set when grouped, which mirrors
      # postgresql handling of empty aggregated results
      it "1 grouped columns returns { [] => 0 }" do
        query = UserQuery.new.group(&.name)

        query.group_count.should eq({} of Array(PG::PGValue) => Int64)
      end

      it "2 grouped columns returns { [] => 0 }" do
        query = UserQuery.new.group(&.name)

        query.group_count.should eq({} of Array(PG::PGValue) => Int64)
      end
    end

    context "when 1 record exists" do
      before_each do
        UserFactory.create do |user|
          user.age(32)
          user.name("Taylor")
        end
      end

      it "0 grouped columns returns { [] => 1 }" do
        query = UserQuery.new

        query.group_count.should eq({[] of String => 1})
      end

      it "1 grouped column (age) returns grouping" do
        query = UserQuery.new.group &.age

        query.group_count.should eq({[32] => 1})
      end

      it "2 grouped columns (age, name) returns grouping" do
        query = UserQuery.new.group(&.age).group(&.name)

        query.group_count.should eq({[32, "Taylor"] => 1})
      end
    end

    context "when matrix [32, Daniel] [32, Taylor] [32, Taylor] [44, Shakira]" do
      before_each do
        UserFactory.create do |user|
          user.age(32)
          user.name("Daniel")
        end
        UserFactory.create do |user|
          user.age(32)
          user.name("Taylor")
        end
        UserFactory.create do |user|
          user.age(32)
          user.name("Taylor")
        end
        UserFactory.create do |user|
          user.age(44)
          user.name("Shakira")
        end
      end

      it "0 grouped columns returns { [] => 4 }" do
        query = UserQuery.new

        query.group_count.should eq({[] of String => 4})
      end

      it "1 grouped columns (age) returns grouping" do
        query = UserQuery.new.group &.age

        query.group_count.should eq({[32] => 3, [44] => 1})
      end

      it "1 grouped columns (age, name) returns grouping" do
        query = UserQuery.new.group(&.age).group(&.name)

        query.group_count.should eq({[32, "Daniel"] => 1, [32, "Taylor"] => 2, [44, "Shakira"] => 1})
      end
    end
  end

  describe "#not" do
    context "with an argument" do
      it "negates the given where condition as 'equal'" do
        UserFactory.new.name("Paul").create

        results = UserQuery.new.name.not.eq("not existing").results
        results.should eq UserQuery.new.results

        results = UserQuery.new.name.not.eq("Paul").results
        results.should eq [] of User

        UserFactory.new.name("Alex").create
        UserFactory.new.name("Sarah").create
        results = UserQuery.new.name.lower.not.eq("alex").results
        results.map(&.name).should eq ["Paul", "Sarah"]
      end
    end

    context "with no arguments" do
      it "negates any previous condition" do
        UserFactory.new.name("Paul").create

        results = UserQuery.new.name.not.eq("Paul").results
        results.should eq [] of User
      end

      it "can be used with operators" do
        UserFactory.new.age(33).name("Joyce").create
        UserFactory.new.age(34).name("Jil").create

        results = UserQuery.new.age.not.gt(33).results
        results.map(&.name).should eq ["Joyce"]
      end
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.age.not.eq(5)

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#in" do
    it "gets records with ids in an array" do
      UserFactory.new.name("Mikias").create
      user = UserQuery.new.first

      results = UserQuery.new.id.in([user.id])
      results.map(&.name).should eq ["Mikias"]
    end

    it "gets records with name not in an array" do
      UserFactory.new.name("Mikias")

      results = UserQuery.new.name.not.in(["Mikias"])
      results.map(&.name).should eq [] of String
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.age.in([1, 2, 3])

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#join methods for associations" do
    it "inner join on belongs to" do
      post = PostFactory.create
      CommentFactory.new.post_id(post.id).create

      query = Comment::BaseQuery.new.join_post
      query.to_sql.should eq ["SELECT comments.custom_id, comments.created_at, comments.updated_at, comments.body, comments.post_id FROM comments INNER JOIN posts ON comments.post_id = posts.custom_id"]

      result = query.first
      result.post.should eq post
    end

    it "doesn't mutate the query when inner joining on belongs to" do
      query = Comment::BaseQuery.new
      original_query_sql = query.to_sql

      query.join_post

      query.to_sql.should eq original_query_sql
    end

    it "inner join on has many" do
      post = PostFactory.create
      comment = CommentFactory.new.post_id(post.id).create

      query = Post::BaseQuery.new.join_comments
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts INNER JOIN comments ON posts.custom_id = comments.post_id"]

      result = query.first
      result.comments.first.should eq comment
    end

    it "doesn't mutate the query when inner joining on has_many" do
      query = Post::BaseQuery.new
      original_query_sql = query.to_sql

      query.join_comments

      query.to_sql.should eq original_query_sql
    end

    it "multiple inner joins on has many through" do
      post = PostFactory.create
      tag = TagFactory.create
      TaggingFactory.new.post_id(post.id).tag_id(tag.id).create

      query = Post::BaseQuery.new.join_tags
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts INNER JOIN taggings ON posts.custom_id = taggings.post_id INNER JOIN tags ON taggings.tag_id = tags.custom_id"]

      result = query.first
      result.tags.first.should eq tag
    end

    it "doesn't mutate the query when inner joining multiple inner joins on has many through" do
      query = Post::BaseQuery.new
      original_query_sql = query.to_sql

      query.join_tags

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#left_join methods for associations" do
    it "left join on belongs to" do
      employee = EmployeeFactory.create

      query = Employee::BaseQuery.new.left_join_manager
      query.to_sql.should eq ["SELECT employees.id, employees.created_at, employees.updated_at, employees.name, employees.manager_id FROM employees LEFT JOIN managers ON employees.manager_id = managers.id"]

      result = query.first
      result.should eq employee
    end

    it "doesn't mutate the query when left joining on belongs to" do
      query = Employee::BaseQuery.new
      original_query_sql = query.to_sql

      query.left_join_manager

      query.to_sql.should eq original_query_sql
    end

    it "left join on has many" do
      post = PostFactory.create

      query = Post::BaseQuery.new.left_join_comments
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts LEFT JOIN comments ON posts.custom_id = comments.post_id"]

      result = query.first
      result.should eq post
    end

    it "doesn't mutate the query when left joining on has many" do
      query = Post::BaseQuery.new
      original_query_sql = query.to_sql

      query.left_join_comments

      query.to_sql.should eq original_query_sql
    end

    it "multiple left joins on has many through" do
      post = PostFactory.create

      query = Post::BaseQuery.new.left_join_tags
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts LEFT JOIN taggings ON posts.custom_id = taggings.post_id LEFT JOIN tags ON taggings.tag_id = tags.custom_id"]

      result = query.first
      result.should eq post
    end

    it "doesn't mutate the query when left joining on has many through" do
      query = Post::BaseQuery.new
      original_query_sql = query.to_sql

      query.left_join_tags

      query.to_sql.should eq original_query_sql
    end
  end

  context "when querying jsonb" do
    describe "simple where query" do
      it "returns 1 result" do
        blob = BlobFactory.new.doc(JSON::Any.new({"foo" => JSON::Any.new("bar")})).create

        query = JSONQuery.new.static_foo
        query.to_sql.should eq ["SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc, blobs.metadata, blobs.media FROM blobs WHERE blobs.doc = $1", "{\"foo\":\"bar\"}"]
        result = query.first
        result.should eq blob

        query2 = JSONQuery.new.foo_with_value("bar")
        query2.to_sql.should eq ["SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc, blobs.metadata, blobs.media FROM blobs WHERE blobs.doc = $1", "{\"foo\":\"bar\"}"]
        result = query2.first
        result.should eq blob

        query3 = JSONQuery.new.foo_with_value("baz")
        query3.to_sql.should eq ["SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc, blobs.metadata, blobs.media FROM blobs WHERE blobs.doc = $1", "{\"foo\":\"baz\"}"]
        expect_raises(Avram::RecordNotFoundError) do
          query3.first
        end
      end
    end
  end

  context "when querying arrays" do
    describe "simple where query" do
      it "returns 1 result" do
        bucket = BucketFactory.new.names(["pumpkin", "zucchini"]).create

        query = BucketQuery.new.names(["pumpkin", "zucchini"])
        query.to_sql.should eq ["SELECT #{Bucket::COLUMN_SQL} FROM buckets WHERE buckets.names = $1", "{\"pumpkin\",\"zucchini\"}"]
        result = query.first
        result.should eq bucket
      end
    end

    describe "#includes" do
      it "queries for a single value in the array" do
        bucket1 = BucketFactory.create &.numbers([9, 13, 26, 4])
        _bucket2 = BucketFactory.create &.numbers([5, 3, 1, 2])

        query = BucketQuery.new.numbers.includes(13)

        query.to_sql.should eq ["SELECT #{Bucket::COLUMN_SQL} FROM buckets WHERE $1 = ANY (buckets.numbers)", "13"]
        query.select_count.should eq(1)
        query.first.id.should eq(bucket1.id)
      end

      it "queries for records that don't include the value" do
        _bucket1 = BucketFactory.create &.numbers([9, 13, 26, 4])
        bucket2 = BucketFactory.create &.numbers([5, 3, 1, 2])

        query = BucketQuery.new.numbers.not.includes(13)

        query.to_sql.should eq ["SELECT #{Bucket::COLUMN_SQL} FROM buckets WHERE $1 != ALL (buckets.numbers)", "13"]
        query.select_count.should eq(1)
        query.first.id.should eq(bucket2.id)
      end
    end
  end

  context "when querying double" do
    describe "simple where double" do
      it "returns 1 result" do
        business = BusinessFactory.new.create

        query = BusinessQuery.new.name(business.name)
        query.to_sql.should eq ["SELECT #{Business::COLUMN_SQL} FROM businesses WHERE businesses.name = $1", business.name]
        result = query.first
        result.should eq business
      end
    end
  end

  context "when querying bytes" do
    context "simple where query" do
      it "returns the correct result" do
        BeatFactory.create &.hash("test".to_slice)

        Beat::BaseQuery.new.hash("test").select_count.should eq(1)
        Beat::BaseQuery.new.hash(Bytes[116, 101, 115, 116]).select_count.should eq(1)
        Beat::BaseQuery.new.hash(Bytes.empty).select_count.should eq(0)
      end
    end
  end

  describe ".truncate" do
    it "truncates the table" do
      10.times { UserFactory.create }
      UserQuery.new.select_count.should eq 10
      # NOTE: we don't test rows_affected here because this isn't
      # available with a truncate statement
      UserQuery.truncate
      UserQuery.new.select_count.should eq 0
    end

    it "deletes associated data when cascade is true" do
      post_with_matching_comment = PostFactory.create
      comment = CommentFactory.new
        .post_id(post_with_matching_comment.id)
        .create

      PostQuery.truncate cascade: true
      PostQuery.new.select_count.should eq 0
      expect_raises(Avram::RecordNotFoundError) do
        CommentQuery.new.find(comment.id)
      end
    end
  end

  describe "#update" do
    it "updates records when wheres are added" do
      UserFactory.create &.available_for_hire(false)
      UserFactory.create &.available_for_hire(false)

      updated_count = ChainedQuery.new.update(available_for_hire: true)

      updated_count.should eq(2)
      results = ChainedQuery.new.results
      results.size.should eq(2)
      results.all?(&.available_for_hire).should be_true
    end

    it "updates some records when wheres are added" do
      helen = UserFactory.create &.available_for_hire(false).name("Helen")
      kate = UserFactory.create &.available_for_hire(false).name("Kate")

      updated_count = ChainedQuery.new.name("Helen").update(available_for_hire: true)

      updated_count.should eq 1
      helen.reload.available_for_hire.should be_true
      kate.reload.available_for_hire.should be_false
    end

    it "only sets columns to `nil` if explicitly set" do
      richard = UserFactory.create &.name("Richard").nickname("Rich")

      updated_count = ChainedQuery.new.update(nickname: nil)

      updated_count.should eq 1
      richard = richard.reload
      richard.nickname.should be_nil
      richard.name.should eq("Richard")
    end

    it "works with JSON" do
      blob = BlobFactory.create &.doc(JSON::Any.new({"updated" => JSON::Any.new(true)}))

      updated_doc = JSON::Any.new({"updated" => JSON::Any.new(false)})
      updated_count = Blob::BaseQuery.new.update(doc: updated_doc)

      updated_count.should eq(1)
      blog = blob.reload
      blog.doc.should eq(updated_doc)
    end

    it "works with arrays" do
      bucket = BucketFactory.create &.names(["Luke"])

      updated_count = Bucket::BaseQuery.new.update(names: ["Rey"])

      updated_count.should eq(1)
      bucket = bucket.reload
      bucket.names.should eq(["Rey"])
    end
  end

  describe "#delete" do
    it "deletes user records that are young" do
      UserFactory.new.name("Tony").age(48).create
      UserFactory.new.name("Peter").age(15).create
      UserFactory.new.name("Bruce").age(49).create
      UserFactory.new.name("Wanda").age(17).create

      ChainedQuery.new.select_count.should eq 4
      # use the glove to remove half of them
      result = ChainedQuery.new.young.delete
      result.should eq 2
      ChainedQuery.new.select_count.should eq 2
    end

    it "delete all records since no where clause is specified" do
      UserFactory.new.name("Steve").age(90).create
      UserFactory.new.name("Nick").age(66).create

      result = ChainedQuery.new.delete
      result.should eq 2
      ChainedQuery.new.select_count.should eq 0
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.delete

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#asc_order" do
    it "orders by a joined table" do
      query = Post::BaseQuery.new.where_comments(Comment::BaseQuery.new.created_at.asc_order)
      query.to_sql[0].should contain "ORDER BY comments.created_at ASC"
    end

    it "orders nulls first" do
      query = Post::BaseQuery.new.published_at.asc_order(:nulls_first)

      query.to_sql[0].should contain "ORDER BY posts.published_at ASC NULLS FIRST"
    end

    it "orders nulls last" do
      query = Post::BaseQuery.new.published_at.asc_order(:nulls_last)

      query.to_sql[0].should contain "ORDER BY posts.published_at ASC NULLS LAST"
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.name.asc_order

      query.to_sql.should eq original_query_sql
    end

    it "resets random order clauses" do
      query = Post::BaseQuery.new.random_order.published_at.asc_order

      query.to_sql[0].should contain "ORDER BY posts.published_at ASC"
      query.to_sql[0].should_not contain "RANDOM ()"
    end
  end

  describe "#random_order" do
    it "orders randomly" do
      query = Post::BaseQuery.new.random_order

      query.to_sql[0].should contain "ORDER BY RANDOM ()"
    end

    it "resets previous order clauses" do
      query = Post::BaseQuery.new.published_at.desc_order.random_order

      query.to_sql[0].should_not contain "posts.published_at DESC"
      query.to_sql[0].should contain "ORDER BY RANDOM ()"
    end
  end

  describe "#clone" do
    it "leaves the original query unaffected" do
      original_query = ChainedQuery.new.young
      new_query = original_query.clone.named("bruce wayne").joined_at.asc_order

      original_query.to_sql.size.should eq 2
      new_query.to_sql.size.should eq 3
      new_query.to_sql[0].should contain "ORDER BY users.joined_at"
      original_query.to_sql[0].should_not contain "ORDER BY"
    end

    it "returns separate results than the original query" do
      UserFactory.create &.name("Purcell").age(22)
      UserFactory.create &.name("Purcell").age(84)
      UserFactory.create &.name("Griffiths").age(55)
      UserFactory.create &.name("Griffiths").age(75)

      original_query = ChainedQuery.new.named("Purcell")
      new_query = original_query.clone.age.gt(30)

      original_query.select_count.should eq 2
      new_query.select_count.should eq 1
    end

    it "clones joined queries" do
      post = PostFactory.create
      CommentFactory.create &.post_id(post.id)

      original_query = Post::BaseQuery.new.where_comments(Comment::BaseQuery.new.created_at.asc_order)
      new_query = original_query.clone.select_count

      original_query.first.should_not eq nil
      new_query.should eq 1
    end

    it "clones preloads" do
      Avram.temp_config(lazy_load_enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)
        posts = Post::BaseQuery.new.preload_comments
        cloned_posts = posts.clone
        posts.first.comments.should eq([comment])
        cloned_posts.first.comments.should eq([comment])
      end
    end

    it "clones nested preloads" do
      Avram.temp_config(lazy_load_enabled: false) do
        item = LineItemFactory.create
        PriceFactory.create &.line_item_id(item.id).in_cents(500)
        product = ProductFactory.create
        LineItemProductFactory.create &.line_item_id(item.id).product_id(product.id)

        products = Product::BaseQuery.new
          .preload_line_items(LineItem::BaseQuery.new.preload_price)
        cloned_products = products.clone
        products.first.line_items.first.price.as(Price).in_cents.should eq(500)
        cloned_products.first.line_items.first.price.should_not be_nil
      end
    end

    it "clones distinct queries" do
      original_query = Post::BaseQuery.new.distinct_on(&.title).clone
      new_query = original_query.published_at.is_nil

      new_query.to_sql[0].should contain "DISTINCT ON"
    end
  end

  describe "#between" do
    it "queries between dates" do
      start_date = 1.week.ago
      end_date = 1.day.ago
      post = PostFactory.create &.published_at(3.days.ago)
      posts = Post::BaseQuery.new.published_at.between(start_date, end_date)

      posts.query.statement.should eq "SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts WHERE posts.published_at >= $1 AND posts.published_at <= $2"
      posts.query.args.should eq [start_date.to_s("%Y-%m-%d %H:%M:%S.%6N %z"), end_date.to_s("%Y-%m-%d %H:%M:%S.%6N %z")]
      posts.first.should eq post
    end

    it "queries between numbers" do
      company = CompanyFactory.create &.sales(50)
      companies = Company::BaseQuery.new.sales.between(1, 100)

      companies.query.statement.should eq "SELECT companies.id, companies.created_at, companies.updated_at, companies.sales, companies.earnings FROM companies WHERE companies.sales >= $1 AND companies.sales <= $2"
      companies.query.args.should eq ["1", "100"]
      companies.first.should eq company
    end

    it "queries between floats" do
      company = CompanyFactory.create &.earnings(300.45)
      companies = Company::BaseQuery.new.earnings.between(123.45, 678.901)

      companies.query.statement.should eq "SELECT companies.id, companies.created_at, companies.updated_at, companies.sales, companies.earnings FROM companies WHERE companies.earnings >= $1 AND companies.earnings <= $2"
      companies.query.args.should eq ["123.45", "678.901"]
      companies.first.should eq company
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.age.between(1, 3)

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#group" do
    it "groups" do
      UserFactory.create &.age(25).name("Michael")
      UserFactory.create &.age(25).name("Dwight")
      UserFactory.create &.age(21).name("Jim")

      users = UserQuery.new.group(&.age).group(&.id)
      users.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users GROUP BY users.age, users.id"
      users.map(&.name).sort!.should eq ["Dwight", "Jim", "Michael"]
    end

    it "raises an error when grouped incorrectly" do
      users = UserQuery.new.group(&.age)

      expect_raises(PQ::PQError, /column "users\.id" must appear in the GROUP BY/) do
        users.map(&.name).should contain "Pam"
      end
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.name("name")
      original_query_sql = query.to_sql

      query.group(&.age)

      query.to_sql.should eq original_query_sql
    end
  end

  context "queries joining with has_one" do
    describe "when you query from the belongs_to side" do
      it "returns a record" do
        line_item = LineItemFactory.create &.name("Thing 1")
        price = PriceFactory.create &.in_cents(100).line_item_id(line_item.id)

        query = PriceQuery.new.where_line_item(LineItemQuery.new.name("Thing 1"))
        query.first.should eq price
      end
    end

    describe "when you query from the has_one side" do
      it "returns a record" do
        line_item = LineItemFactory.create &.name("Thing 1")
        PriceFactory.create &.in_cents(100).line_item_id(line_item.id)

        query = LineItemQuery.new.where_price(PriceQuery.new.in_cents(100))
        query.first.should eq line_item
      end
    end
  end

  describe "#to_prepared_sql" do
    it "returns the full SQL with args combined" do
      query = Post::BaseQuery.new.title("The Short Post")
      query.to_prepared_sql.should eq(%{SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts WHERE posts.title = 'The Short Post'})

      query = Bucket::BaseQuery.new.names(["Larry", "Moe", "Curly"]).numbers([1, 2, 3])
      query.to_prepared_sql.should eq(%{SELECT #{Bucket::COLUMN_SQL} FROM buckets WHERE buckets.names = '{"Larry","Moe","Curly"}' AND buckets.numbers = '{1,2,3}'})

      query = Blob::BaseQuery.new.doc(JSON::Any.new({"properties" => JSON::Any.new("sold")}))
      query.to_prepared_sql.should eq(%{SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc, blobs.metadata, blobs.media FROM blobs WHERE blobs.doc = '{"properties":"sold"}'})

      query = UserQuery.new.name.in(["Don", "Juan"]).age.gt(30)
      query.to_prepared_sql.should eq(%{SELECT #{User::COLUMN_SQL} FROM users WHERE users.name = ANY ('{"Don","Juan"}') AND users.age > '30'})
    end

    it "returns the full SQL with a lot of args" do
      a_week = 1.week.ago
      an_hour = 1.hour.ago
      a_day = 1.day.ago

      query = UserQuery.new
        .name("Don")
        .age.gt(21)
        .age.lt(99)
        .nickname.ilike("j%")
        .nickname.ilike("%y")
        .joined_at.gt(a_week)
        .joined_at.lt(an_hour)
        .average_score.gt(1.2)
        .average_score.lt(4.9)
        .available_for_hire(true)
        .created_at(a_day)

      query.to_prepared_sql.should eq(%{SELECT users.id, users.created_at, users.updated_at, users.name, users.age, users.year_born, users.nickname, users.joined_at, users.total_score, users.average_score, users.available_for_hire FROM users WHERE users.name = 'Don' AND users.age > '21' AND users.age < '99' AND users.nickname ILIKE 'j%' AND users.nickname ILIKE '%y' AND users.joined_at > '#{a_week.to_s("%F %X.%6N %z")}' AND users.joined_at < '#{an_hour.to_s("%F %X.%6N %z")}' AND users.average_score > '1.2' AND users.average_score < '4.9' AND users.available_for_hire = 'true' AND users.created_at = '#{a_day.to_s("%F %X.%6N %z")}'})
    end
  end

  describe "#reset_limit" do
    it "resets the limit to nil" do
      users = UserQuery.new.limit(10)
      users.query.limit.should eq 10
      users.reset_limit.query.limit.should eq nil
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.limit(10)
      original_query_sql = query.to_sql

      query.reset_limit

      query.to_sql.should eq original_query_sql
    end
  end

  describe "#reset_offset" do
    it "resets the offset to nil" do
      users = UserQuery.new.offset(10)
      users.query.offset.should eq 10
      users.reset_offset.query.offset.should eq nil
    end

    it "doesn't mutate the query" do
      query = UserQuery.new.offset(10)
      original_query_sql = query.to_sql

      query.reset_offset

      query.to_sql.should eq original_query_sql
    end
  end

  describe "with query cache" do
    it "only runs the query once" do
      # We're testing the actual caching
      Fiber.current.query_cache = LuckyCache::MemoryStore.new
      Avram.temp_config(query_cache_enabled: true) do
        UserFactory.create &.name("Amy")
        CachedUserQuery.query_counter.should eq(0)

        CachedUserQuery.new.name("Amy").first
        CachedUserQuery.new.name("Amy").first
        user = CachedUserQuery.new.name("Amy").first

        CachedUserQuery.query_counter.should eq(1)
        user.name.should eq("Amy")
      end
    end

    it "uses the correct cache_key for .any?" do
      Fiber.current.query_cache = LuckyCache::MemoryStore.new
      Avram.temp_config(query_cache_enabled: true) do
        UserFactory.create &.name("Amy")

        query = CachedUserQuery.new.name("Amy")
        store = query.cache_store.as(LuckyCache::MemoryStore)
        # TODO: https://github.com/luckyframework/lucky_cache/issues/7
        store.@cache.size.should eq(0)
        query.any?.should eq(true) # ameba:disable Performance/AnyInsteadOfEmpty
        query.results.size.should eq(1)
        query.any?.should eq(true) # ameba:disable Performance/AnyInsteadOfEmpty

        store.@cache.size.should eq(2)
      end
    end

    it "uses the correct cache_key for .select_count" do
      Fiber.current.query_cache = LuckyCache::MemoryStore.new
      Avram.temp_config(query_cache_enabled: true) do
        UserFactory.create &.name("Amy")

        query = CachedUserQuery.new
        store = query.cache_store.as(LuckyCache::MemoryStore)
        # TODO: https://github.com/luckyframework/lucky_cache/issues/7
        store.@cache.size.should eq(0)
        query.select_count.should eq(1)
        query.results.size.should eq(1)
        query.select_count.should eq(1)

        store.@cache.size.should eq(2)
      end
    end
  end
end
