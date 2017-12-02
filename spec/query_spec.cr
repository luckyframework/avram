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
      insert_a_user
      UserQuery.new.first.name.should eq "Paul"
    end
  end

  describe "#find" do
    it "gets the record with the given id" do
      insert_a_user
      user = UserQuery.new.first

      UserQuery.new.find(user.id).should eq user
    end

    it "raises RecordNotFound if no record is found with the given id (Int32)" do
      expect_raises(LuckyRecord::RecordNotFoundError, "") do
        UserQuery.new.find(1)
      end
    end

    it "raises RecordNotFound if no record is found with the given id (String)" do
      expect_raises(LuckyRecord::RecordNotFoundError, "") do
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
  end

  describe "#limit" do
    it "adds a limit clause" do
      queryable = UserQuery.new.limit(2)

      queryable.query.statement.should eq "SELECT #{User::COLUMNS} FROM users LIMIT 2"
    end

    it "works while chaining" do
      insert_a_user
      insert_a_user
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

      insert_a_user
      count = UserQuery.new.count
      count.should eq 1
    end

    it "works with ORDER BY by removing the ordering" do
      insert_a_user

      query = UserQuery.new.name.desc_order

      query.count.should eq 1
    end

    it "works with chained where" do
      insert_a_user(age: 30)
      insert_a_user(age: 31)

      query = UserQuery.new.age.gte(31)

      query.count.should eq 1
    end
  end

  describe "#not with an argument" do
    it "negates the given where condition as 'equal'" do
      insert_a_user(name: "Paul")

      results = UserQuery.new.name.not("not existing").results
      results.should eq UserQuery.new.results

      results = UserQuery.new.name.not("Paul").results
      results.should eq [] of User

      insert_a_user(name: "Alex")
      insert_a_user(name: "Sarah")
      results = UserQuery.new.name.lower.not("alex").results
      results.map(&.name).should eq ["Paul", "Sarah"]
    end
  end

  describe "#not with no arguments" do
    it "negates any previous condition" do
      insert_a_user

      results = UserQuery.new.name.not.is("Paul").results
      results.should eq [] of User
    end

    it "can be used with operators" do
      insert_a_user(name: "Joyce", age: 33)
      insert_a_user(name: "Jil", age: 34)

      results = UserQuery.new.age.not.gt(33).results
      results.map(&.name).should eq ["Joyce"]
    end
  end

  describe "#in" do
    it "gets records with ids in an array" do
      insert_a_user(name: "Mikias")
      user = UserQuery.new.first

      results = UserQuery.new.id.in([user.id])
      results.map(&.name).should eq ["Mikias"]
    end

    it "gets records with name not in an array" do
      insert_a_user(name: "Mikias")

      results = UserQuery.new.name.not.in(["Mikias"])
      results.map(&.name).should eq [] of String
    end
  end
end

private def insert_a_user(name = "Paul", age = 34)
  LuckyRecord::Repo.run do |db|
    db.exec "INSERT INTO users(name, created_at, updated_at, age, joined_at) VALUES ($1, $2, $3, $4, $5)",
      name,
      Time.now,
      Time.now,
      age,
      Time.now
  end
end
