require "./spec_helper"

private class ChainedQuery < User::BaseQuery
  def young
    age.lte(18)
  end

  def named(value)
    name(value)
  end
end

describe LuckyRecord::Query do
  it "can chain scope methods" do
    ChainedQuery.new.young.named("Paul")
  end

  describe "#first" do
    it "gets the first row from the database" do
      UserBox.new.name("First").save
      UserBox.new.name("Last").save

      UserQuery.new.first.name.should eq "First"
    end

    it "raises RecordNotFound if no record is found" do
      expect_raises(LuckyRecord::RecordNotFoundError) do
        UserQuery.new.first
      end
    end
  end

  describe "#first?" do
    it "gets the first row from the database" do
      UserBox.new.name("First").save
      UserBox.new.name("Last").save

      user = UserQuery.new.first?
      user.should_not be_nil
      user.not_nil!.name.should eq "First"
    end

    it "returns nil if no record found" do
      UserQuery.new.first?.should be_nil
    end
  end

  describe "#last" do
    it "gets the last row from the database" do
      UserBox.new.name("First").save
      UserBox.new.name("Last").save

      UserQuery.new.last.name.should eq "Last"
    end

    it "reverses the order of ordered queries" do
      UserBox.new.name("Alpha").save
      UserBox.new.name("Charlie").save
      UserBox.new.name("Bravo").save

      UserQuery.new.order_by(:name, :desc).last.name.should eq "Alpha"
    end

    it "raises RecordNotFound if no record is found" do
      expect_raises(LuckyRecord::RecordNotFoundError) do
        UserQuery.new.last
      end
    end
  end

  describe "#last?" do
    it "gets the last row from the database" do
      UserBox.new.name("First").save
      UserBox.new.name("Last").save

      last = UserQuery.new.last?
      last.should_not be_nil
      last && last.name.should eq "Last"
    end

    it "returns nil if last record is not found" do
      UserQuery.new.last?.should be_nil
    end
  end

  describe "#find" do
    it "gets the record with the given id" do
      UserBox.save
      user = UserQuery.new.first

      UserQuery.new.find(user.id).should eq user
    end

    it "raises RecordNotFound if no record is found with the given id (Int32)" do
      expect_raises(LuckyRecord::RecordNotFoundError) do
        UserQuery.new.find(1)
      end
    end

    it "raises RecordNotFound if no record is found with the given id (String)" do
      expect_raises(LuckyRecord::RecordNotFoundError) do
        UserQuery.new.find("1")
      end
    end

    it "raises PQ::PQError if no record is found with letter-only id (String)" do
      expect_raises(PQ::PQError, "") do
        UserQuery.new.find("id")
      end
    end
  end

  describe "#where" do
    it "chains wheres" do
      query = UserQuery.new.where(:first_name, "Paul").where(:last_name, "Smith").query

      query.statement.should eq "SELECT #{User::COLUMNS} FROM users WHERE first_name = $1 AND last_name = $2"
      query.args.should eq ["Paul", "Smith"]
    end

    it "handles int" do
      query = UserQuery.new.where(:id, 1).query

      query.statement.should eq "SELECT #{User::COLUMNS} FROM users WHERE id = $1"
      query.args.should eq ["1"]
    end

    it "accepts raw sql with bindings and chains with itself" do
      user = UserBox.new.name("Mikias Abera").age(26).nickname("miki").save
      users = UserQuery.new.where("name = ? AND age = ?", "Mikias Abera", 26).where(:nickname, "miki")

      users.query.statement.should eq "SELECT #{User::COLUMNS} FROM users WHERE nickname = $1 AND name = 'Mikias Abera' AND age = 26"

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

      queryable.query.statement.should eq "SELECT #{User::COLUMNS} FROM users LIMIT 2"
    end

    it "works while chaining" do
      UserBox.save
      UserBox.save
      users = UserQuery.new.name.desc_order.limit(1)

      users.query.statement.should eq "SELECT #{User::COLUMNS} FROM users ORDER BY users.name DESC LIMIT 1"

      users.results.size.should eq(1)
    end
  end

  describe "#offset" do
    it "adds an offset clause" do
      query = UserQuery.new.offset(2).query

      query.statement.should eq "SELECT #{User::COLUMNS} FROM users OFFSET 2"
    end
  end

  describe "#order_by" do
    it "adds an order clause" do
      query = UserQuery.new.order_by(:name, :asc).query

      query.statement.should eq "SELECT #{User::COLUMNS} FROM users ORDER BY users.name ASC"
    end
  end

  describe "#count" do
    it "returns the number of database rows" do
      count = UserQuery.new.count
      count.should eq 0

      UserBox.save
      count = UserQuery.new.count
      count.should eq 1
    end

    it "works with ORDER BY by removing the ordering" do
      UserBox.save

      query = UserQuery.new.name.desc_order

      query.count.should eq 1
    end

    it "works with chained where" do
      UserBox.new.age(30).save
      UserBox.new.age(31).save

      query = UserQuery.new.age.gte(31)

      query.count.should eq 1
    end

    it "raises when used with offset or limit" do
      expect_raises(LuckyRecord::UnsupportedQueryError) do
        UserQuery.new.limit(1).count
      end

      expect_raises(LuckyRecord::UnsupportedQueryError) do
        UserQuery.new.offset(1).count
      end
    end
  end

  describe "#not with an argument" do
    it "negates the given where condition as 'equal'" do
      UserBox.new.name("Paul").save

      results = UserQuery.new.name.not("not existing").results
      results.should eq UserQuery.new.results

      results = UserQuery.new.name.not("Paul").results
      results.should eq [] of User

      UserBox.new.name("Alex").save
      UserBox.new.name("Sarah").save
      results = UserQuery.new.name.lower.not("alex").results
      results.map(&.name).should eq ["Paul", "Sarah"]
    end
  end

  describe "#not with no arguments" do
    it "negates any previous condition" do
      UserBox.new.name("Paul").save

      results = UserQuery.new.name.not.is("Paul").results
      results.should eq [] of User
    end

    it "can be used with operators" do
      UserBox.new.age(33).name("Joyce").save
      UserBox.new.age(34).name("Jil").save

      results = UserQuery.new.age.not.gt(33).results
      results.map(&.name).should eq ["Joyce"]
    end
  end

  describe "#in" do
    it "gets records with ids in an array" do
      UserBox.new.name("Mikias").save
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
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      query = Comment::BaseQuery.new.join_posts
      query.to_sql.should eq ["SELECT comments.id, comments.created_at, comments.updated_at, comments.body, comments.post_id FROM comments INNER JOIN posts ON comments.id = posts.id"]

      result = query.first
      result.post.should eq post
    end

    it "inner join on has many" do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      query = Post::BaseQuery.new.join_comments
      query.to_sql.should eq ["SELECT posts.id, posts.created_at, posts.updated_at, posts.title, posts.published_at FROM posts INNER JOIN comments ON posts.id = comments.post_id"]

      result = query.first
      result.comments.first.should eq comment
    end
  end
end
