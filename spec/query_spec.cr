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

class ArrayQuery < Bucket::BaseQuery
end

describe Avram::Query do
  it "can chain scope methods" do
    ChainedQuery.new.young.named("Paul")
  end

  it "can select distinct" do
    query = UserQuery.new.distinct.query

    query.statement.should eq "SELECT DISTINCT #{User::COLUMN_SQL} FROM users"
    query.args.should eq [] of String
  end

  it "can reset order" do
    query = UserQuery.new.order_by(:some_column, :asc).reset_order.query

    query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users"
    query.args.should eq [] of String
  end

  it "can select distinct on a specific column" do
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

      user = (user_query = UserQuery.new).first?
      user.should_not be_nil
      user.not_nil!.name.should eq "First"
      user_query.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY users.id ASC LIMIT 1"
    end

    it "returns nil if no record found" do
      UserQuery.new.first?.should be_nil
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

      last = UserQuery.last?
      last.should_not be_nil
      last && last.name.should eq "Last"
    end

    it "returns nil if last record is not found" do
      UserQuery.last?.should be_nil
    end
  end

  describe "#last?" do
    it "gets the last row from the database" do
      UserBox.new.name("First").create
      UserBox.new.name("Last").create

      last = (user_query = UserQuery.new).last?
      last.should_not be_nil
      last && last.name.should eq "Last"
      user_query.query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY users.id DESC LIMIT 1"
    end

    it "returns nil if last record is not found" do
      UserQuery.new.last?.should be_nil
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
  end

  describe "#offset" do
    it "adds an offset clause" do
      query = UserQuery.new.offset(2).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users OFFSET 2"
    end
  end

  describe "#order_by" do
    it "adds an order clause" do
      query = UserQuery.new.order_by(:name, :asc).query

      query.statement.should eq "SELECT #{User::COLUMN_SQL} FROM users ORDER BY name ASC"
    end
  end

  describe "#none" do
    it "returns 0 records" do
      UserBox.create

      query = UserQuery.new.none

      query.results.size.should eq 0
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
  end

  describe "#select_average" do
    it "returns the average" do
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
      average = UserQuery.new.age.select_average
      average.should eq 2.0
    end

    it "works with chained where clauses" do
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
      average = UserQuery.new.age.gte(2).age.select_average
      average.should eq 2.5
    end
  end

  describe "#select_sum" do
    it "returns the sum" do
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
      sum = UserQuery.new.age.select_sum
      sum.should eq 6
    end

    it "works with chained where clauses" do
      UserBox.create &.age(2)
      UserBox.create &.age(1)
      UserBox.create &.age(3)
      sum = UserQuery.new.age.gte(2).age.select_sum
      sum.should eq 5
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
  end

  describe "#not with an argument" do
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

  describe "#not with no arguments" do
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
  end

  describe "#join methods for associations" do
    it "inner join on belongs to" do
      post = PostBox.create
      comment = CommentBox.new.post_id(post.id).create

      query = Comment::BaseQuery.new.join_posts
      query.to_sql.should eq ["SELECT comments.custom_id, comments.created_at, comments.updated_at, comments.body, comments.post_id FROM comments INNER JOIN posts ON comments.post_id = posts.custom_id"]

      result = query.first
      result.post.should eq post
    end

    it "inner join on has many" do
      post = PostBox.create
      comment = CommentBox.new.post_id(post.id).create

      query = Post::BaseQuery.new.join_comments
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts INNER JOIN comments ON posts.custom_id = comments.post_id"]

      result = query.first
      result.comments.first.should eq comment
    end

    it "multiple inner joins on has many through" do
      post = PostBox.create
      tag = TagBox.create
      tagging = TaggingBox.new.post_id(post.id).tag_id(tag.id).create

      query = Post::BaseQuery.new.join_tags
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts INNER JOIN taggings ON posts.custom_id = taggings.post_id INNER JOIN tags ON taggings.tag_id = tags.custom_id"]

      result = query.first
      result.tags.first.should eq tag
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

    it "left join on has many" do
      post = PostBox.create

      query = Post::BaseQuery.new.left_join_comments
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts LEFT JOIN comments ON posts.custom_id = comments.post_id"]

      result = query.first
      result.should eq post
    end

    it "multiple left joins on has many through" do
      post = PostBox.create

      query = Post::BaseQuery.new.left_join_tags
      query.to_sql.should eq ["SELECT posts.custom_id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts LEFT JOIN taggings ON posts.custom_id = taggings.post_id LEFT JOIN tags ON taggings.tag_id = tags.custom_id"]

      result = query.first
      result.should eq post
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

        query = ArrayQuery.new.names(["pumpkin", "zucchini"])
        query.to_sql.should eq ["SELECT buckets.id, buckets.created_at, buckets.updated_at, buckets.bools, buckets.small_numbers, buckets.numbers, buckets.big_numbers, buckets.names FROM buckets WHERE buckets.names = $1", "{\"pumpkin\",\"zucchini\"}"]
        result = query.first
        result.should eq bucket
      end
    end
  end

  describe "truncate" do
    it "truncates the table" do
      10.times { UserBox.create }
      UserQuery.new.select_count.should eq 10
      UserQuery.truncate
      UserQuery.new.select_count.should eq 0
    end
  end

  describe "delete_all" do
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
  end

  describe "ordering" do
    it "orders by a joined table" do
      query = Post::BaseQuery.new.where_comments(Comment::BaseQuery.new.created_at.asc_order)
      query.to_sql[0].should contain "ORDER BY comments.created_at ASC"
    end
  end

  describe "cloning queries" do
    it "leaves the original query unaffected" do
      original_query = ChainedQuery.new.young
      new_query = original_query.clone.named("bruce wayne").joined_at.asc_order

      original_query.to_sql.size.should eq 2
      new_query.to_sql.size.should eq 3
      new_query.to_sql[0].should contain "ORDER BY users.joined_at"
      original_query.to_sql[0].should_not contain "ORDER BY"
    end

    it "returns separate results than the original query" do
      UserBox.new.name("Purcell").age(22).create
      UserBox.new.name("Purcell").age(84).create
      UserBox.new.name("Griffiths").age(55).create
      UserBox.new.name("Griffiths").age(75).create

      original_query = ChainedQuery.new.named("Purcell")
      new_query = original_query.clone.age.gt(30)

      original_query.select_count.should eq 2
      new_query.select_count.should eq 1
    end

    it "clones joined queries" do
      post = PostBox.new.create
      CommentBox.new.post_id(post.id).create

      original_query = Post::BaseQuery.new.where_comments(Comment::BaseQuery.new.created_at.asc_order)
      new_query = original_query.clone.select_count

      original_query.first.should_not eq nil
      new_query.should eq 1
    end
  end
end
