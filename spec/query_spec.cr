require "./spec_helper"

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

describe Avram::Query do
  it "can chain scope methods" do
    ChainedQuery.new.young.named("Paul")
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
      UserBox.new.name("Purcell").age(22).create
      UserBox.new.name("Purcell").age(84).create
      UserBox.new.name("Griffiths").age(55).create
      UserBox.new.name("Griffiths").age(75).create
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
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

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
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

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
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

      user = UserQuery.first?
      user.should_not be_nil
      user.not_nil!.name.should eq "First"
    end

    it "returns nil if no record found" do
      UserQuery.first?.should be_nil
    end
  end

  describe "#first?" do
    it "gets the first row from the database" do
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

      user = UserQuery.new.first?
      user_query = Avram::Events::QueryEvent.logged_events.last.query

      user.should_not be_nil
      user.not_nil!.name.should eq "First"
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
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

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
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

      UserQuery.new.last.name.should eq "Last"
    end

    it "reverses the order of ordered queries" do
      UserBox.new.name("Alpha").create
      UserBox.new.name("Charlie").create
      UserBox.new.name("Bravo").create

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
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

      user = UserQuery.last?

      user.should_not be_nil
      user.not_nil!.name.should eq "Last"
    end

    it "returns nil if last record is not found" do
      UserQuery.last?.should be_nil
    end
  end

  describe "#last?" do
    it "gets the last row from the database" do
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

      user = UserQuery.new.last?
      user_query = Avram::Events::QueryEvent.logged_events.last.query

      user.should_not be_nil
      user.not_nil!.name.should eq "Last"
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

  describe ".find" do
    it "gets the record with the given id" do
      UserBox.create
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
      UserBox.create
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
      user = UserBox.new.create
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
      user = UserBox.new.name("Mikias Abera").age(26).nickname("miki").create
      users = UserQuery.new.where("name = ? AND age = ?", "Mikias Abera", 26).where(:nickname, "miki")

      users.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users WHERE nickname = $1 AND name = 'Mikias Abera' AND age = 26"

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

  describe "#limit" do
    it "adds a limit clause" do
      queryable = UserQuery.new.limit(2)

      queryable.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users LIMIT 2"
    end

    it "works while chaining" do
      UserBox.create
      UserBox.create
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
      UserBox.create

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
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
      min = UserQuery.new.age.select_min
      min.should eq 1
    end

    it "works with chained where clauses" do
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
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
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
      max = UserQuery.new.age.select_max
      max.should eq 3
    end

    it "works with chained where clauses" do
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
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
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
      average = UserQuery.new.age.select_average
      average.should eq 2
      average.should be_a Float64
    end

    it "returns nil if there are no records" do
      average = UserQuery.new.age.select_average
      average.should be_nil
    end

    it "works with chained where clauses" do
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
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
      UserBox.create &.total_score(2000)
      UserBox.create &.total_score(1000)
      UserBox.create &.total_score(3000)
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
      UserBox.create &.total_score(2000)
      UserBox.create &.total_score(1000)
      UserBox.create &.total_score(3000)
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
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
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
      UserBox.create &.year_born(1990_i16)
      UserBox.create &.year_born(1995_i16)
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
      scores.each { |score| UserBox.create &.average_score(score) }
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

      UserBox.create
      count = UserQuery.new.select_count
      count.should eq 1
    end

    it "works with ORDER BY by removing the ordering" do
      UserBox.create

      query = UserQuery.new.name.desc_order

      query.select_count.should eq 1
    end

    it "works with chained where" do
      UserBox.new.age(30).create
      UserBox.new.age(31).create

      query = UserQuery.new.age.gte(31)

      query.select_count.should eq 1
    end

    it "raises when used with offset or limit" do
      expect_raises(Avram::UnsupportedQueryError) do
        UserQuery.new.limit(1).select_count
      end

      expect_raises(Avram::UnsupportedQueryError) do
        UserQuery.new.offset(1).select_count
      end
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

  describe "#not" do
    context "with an argument" do
      it "negates the given where condition as 'equal'" do
        UserBox.new.name("Paul").create

        results = UserQuery.new.name.not.eq("not existing").results
        results.should eq UserQuery.new.results

        results = UserQuery.new.name.not.eq("Paul").results
        results.should eq [] of User

        UserBox.new.name("Alex").create
        UserBox.new.name("Sarah").create
        results = UserQuery.new.name.lower.not.eq("alex").results
        results.map(&.name).should eq ["Paul", "Sarah"]
      end
    end

    context "with no arguments" do
      it "negates any previous condition" do
        UserBox.new.name("Paul").create

        results = UserQuery.new.name.not.eq("Paul").results
        results.should eq [] of User
      end

      it "can be used with operators" do
        UserBox.new.age(33).name("Joyce").create
        UserBox.new.age(34).name("Jil").create

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
      UserBox.new.name("Mikias").create
      user = UserQuery.new.first

      results = UserQuery.new.id.in([user.id])
      results.map(&.name).should eq ["Mikias"]
    end

    it "gets records with name not in an array" do
      UserBox.new.name("Mikias")

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
      post = PostBox.create
      CommentBox.new.post_id(post.id).create

      query = Comment::BaseQuery.new.join_posts
      query.to_sql.should eq ["SELECT comments.custom_id, comments.created_at, comments.updated_at, comments.body, comments.post_id FROM comments INNER JOIN posts ON comments.post_id = posts.custom_id"]

      result = query.first
      result.post.should eq post
    end

    it "doesn't mutate the query when inner joining on belongs to" do
      query = Comment::BaseQuery.new
      original_query_sql = query.to_sql

      query.join_posts

      query.to_sql.should eq original_query_sql
    end

    it "inner join on has many" do
      post = PostBox.create
      comment = CommentBox.new.post_id(post.id).create

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
      post = PostBox.create
      tag = TagBox.create
      TaggingBox.new.post_id(post.id).tag_id(tag.id).create

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
      employee = EmployeeBox.create

      query = Employee::BaseQuery.new.left_join_managers
      query.to_sql.should eq ["SELECT employees.id, employees.created_at, employees.updated_at, employees.name, employees.manager_id FROM employees LEFT JOIN managers ON employees.manager_id = managers.id"]

      result = query.first
      result.should eq employee
    end

    it "doesn't mutate the query when left joining on belongs to" do
      query = Employee::BaseQuery.new
      original_query_sql = query.to_sql

      query.left_join_managers

      query.to_sql.should eq original_query_sql
    end

    it "left join on has many" do
      post = PostBox.create

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
      post = PostBox.create

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
        blob = BlobBox.new.doc(JSON::Any.new({"foo" => JSON::Any.new("bar")})).create

        query = JSONQuery.new.static_foo
        query.to_sql.should eq ["SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc FROM blobs WHERE blobs.doc = $1", "{\"foo\":\"bar\"}"]
        result = query.first
        result.should eq blob

        query2 = JSONQuery.new.foo_with_value("bar")
        query2.to_sql.should eq ["SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc FROM blobs WHERE blobs.doc = $1", "{\"foo\":\"bar\"}"]
        result = query2.first
        result.should eq blob

        query3 = JSONQuery.new.foo_with_value("baz")
        query3.to_sql.should eq ["SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc FROM blobs WHERE blobs.doc = $1", "{\"foo\":\"baz\"}"]
        expect_raises(Avram::RecordNotFoundError) do
          query3.first
        end
      end
    end
  end

  context "when querying arrays" do
    describe "simple where query" do
      it "returns 1 result" do
        bucket = BucketBox.new.names(["pumpkin", "zucchini"]).create

        query = BucketQuery.new.names(["pumpkin", "zucchini"])
        query.to_sql.should eq ["SELECT #{Bucket::COLUMN_SQL} FROM buckets WHERE buckets.names = $1", "{\"pumpkin\",\"zucchini\"}"]
        result = query.first
        result.should eq bucket
      end
    end
  end

  describe ".truncate" do
    it "truncates the table" do
      10.times { UserBox.create }
      UserQuery.new.select_count.should eq 10
      UserQuery.truncate
      UserQuery.new.select_count.should eq 0
    end
  end

  describe "#update" do
    it "updates records when wheres are added" do
      UserBox.create &.available_for_hire(false)
      UserBox.create &.available_for_hire(false)

      updated_count = ChainedQuery.new.update(available_for_hire: true)

      updated_count.should eq(2)
      results = ChainedQuery.new.results
      results.size.should eq(2)
      results.all?(&.available_for_hire).should be_true
    end

    it "updates some records when wheres are added" do
      helen = UserBox.create &.available_for_hire(false).name("Helen")
      kate = UserBox.create &.available_for_hire(false).name("Kate")

      updated_count = ChainedQuery.new.name("Helen").update(available_for_hire: true)

      updated_count.should eq 1
      helen.reload.available_for_hire.should be_true
      kate.reload.available_for_hire.should be_false
    end

    it "only sets columns to `nil` if explicitly set" do
      richard = UserBox.create &.name("Richard").nickname("Rich")

      updated_count = ChainedQuery.new.update(nickname: nil)

      updated_count.should eq 1
      richard = richard.reload
      richard.nickname.should be_nil
      richard.name.should eq("Richard")
    end

    it "works with JSON" do
      blob = BlobBox.create &.doc(JSON::Any.new({"updated" => JSON::Any.new(true)}))

      updated_doc = JSON::Any.new({"updated" => JSON::Any.new(false)})
      updated_count = Blob::BaseQuery.new.update(doc: updated_doc)

      updated_count.should eq(1)
      blog = blob.reload
      blog.doc.should eq(updated_doc)
    end

    it "works with arrays" do
      bucket = BucketBox.create &.names(["Luke"])

      updated_count = Bucket::BaseQuery.new.update(names: ["Rey"])

      updated_count.should eq(1)
      bucket = bucket.reload
      bucket.names.should eq(["Rey"])
    end
  end

  describe "#delete" do
    it "deletes user records that are young" do
      UserBox.new.name("Tony").age(48).create
      UserBox.new.name("Peter").age(15).create
      UserBox.new.name("Bruce").age(49).create
      UserBox.new.name("Wanda").age(17).create

      ChainedQuery.new.select_count.should eq 4
      # use the glove to remove half of them
      result = ChainedQuery.new.young.delete
      result.should eq 2
      ChainedQuery.new.select_count.should eq 2
    end

    it "delete all records since no where clause is specified" do
      UserBox.new.name("Steve").age(90).create
      UserBox.new.name("Nick").age(66).create

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
      UserBox.create &.name("Purcell").age(22)
      UserBox.create &.name("Purcell").age(84)
      UserBox.create &.name("Griffiths").age(55)
      UserBox.create &.name("Griffiths").age(75)

      original_query = ChainedQuery.new.named("Purcell")
      new_query = original_query.clone.age.gt(30)

      original_query.select_count.should eq 2
      new_query.select_count.should eq 1
    end

    it "clones joined queries" do
      post = PostBox.create
      CommentBox.create &.post_id(post.id)

      original_query = Post::BaseQuery.new.where_comments(Comment::BaseQuery.new.created_at.asc_order)
      new_query = original_query.clone.select_count

      original_query.first.should_not eq nil
      new_query.should eq 1
    end

    it "clones preloads" do
      Avram.temp_config(lazy_load_enabled: false) do
        post = PostBox.create
        comment = CommentBox.create &.post_id(post.id)
        posts = Post::BaseQuery.new.preload_comments
        cloned_posts = posts.clone
        posts.first.comments.should eq([comment])
        cloned_posts.first.comments.should eq([comment])
      end
    end

    it "clones nested preloads" do
      Avram.temp_config(lazy_load_enabled: false) do
        item = LineItemBox.create
        PriceBox.create &.line_item_id(item.id).in_cents(500)
        product = ProductBox.create
        LineItemProductBox.create &.line_item_id(item.id).product_id(product.id)

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
      post = PostBox.create &.published_at(3.days.ago)
      posts = Post::BaseQuery.new.published_at.between(start_date, end_date)

      posts.query.statement.should eq "SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts WHERE posts.published_at >= $1 AND posts.published_at <= $2"
      posts.query.args.should eq [start_date.to_s("%Y-%m-%d %H:%M:%S %:z"), end_date.to_s("%Y-%m-%d %H:%M:%S %:z")]
      posts.first.should eq post
    end

    it "queries between numbers" do
      company = CompanyBox.create &.sales(50)
      companies = Company::BaseQuery.new.sales.between(1, 100)

      companies.query.statement.should eq "SELECT companies.id, companies.created_at, companies.updated_at, companies.sales, companies.earnings FROM companies WHERE companies.sales >= $1 AND companies.sales <= $2"
      companies.query.args.should eq ["1", "100"]
      companies.first.should eq company
    end

    it "queries between floats" do
      company = CompanyBox.create &.earnings(300.45)
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
      UserBox.create &.age(25).name("Michael")
      UserBox.create &.age(25).name("Dwight")
      UserBox.create &.age(21).name("Jim")

      users = UserQuery.new.group(&.age).group(&.id)
      users.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users GROUP BY users.age, users.id"
      users.map(&.name).should eq ["Dwight", "Michael", "Jim"]
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
        line_item = LineItemBox.create &.name("Thing 1")
        price = PriceBox.create &.in_cents(100).line_item_id(line_item.id)

        query = PriceQuery.new.where_line_items(LineItemQuery.new.name("Thing 1"))
        query.first.should eq price
      end
    end

    describe "when you query from the has_one side" do
      it "returns a record" do
        line_item = LineItemBox.create &.name("Thing 1")
        PriceBox.create &.in_cents(100).line_item_id(line_item.id)

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
      query.to_prepared_sql.should eq(%{SELECT blobs.id, blobs.created_at, blobs.updated_at, blobs.doc FROM blobs WHERE blobs.doc = '{"properties":"sold"}'})

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

      query.to_prepared_sql.should eq(%{SELECT users.id, users.created_at, users.updated_at, users.name, users.age, users.year_born, users.nickname, users.joined_at, users.total_score, users.average_score, users.available_for_hire FROM users WHERE users.name = 'Don' AND users.age > '21' AND users.age < '99' AND users.nickname ILIKE 'j%' AND users.nickname ILIKE '%y' AND users.joined_at > '#{a_week}' AND users.joined_at < '#{an_hour}' AND users.average_score > '1.2' AND users.average_score < '4.9' AND users.available_for_hire = 'true' AND users.created_at = '#{a_day}'})
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
end
