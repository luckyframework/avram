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
  end

  describe "#where" do
    it "chains wheres" do
      query = UserQuery.new.where(:first_name, "Paul").where(:last_name, "Smith").query

      query.statement.should eq "SELECT * FROM users WHERE first_name = $1 AND last_name = $2"
      query.args.should eq ["Paul", "Smith"]
    end

    it "handles int" do
      query = UserQuery.new.where(:id, 1).query

      query.statement.should eq "SELECT * FROM users WHERE id = $1"
      query.args.should eq ["1"]
    end
  end

  describe "#limit" do
    it "adds a limit clause" do
      query = UserQuery.new.limit(2).query

      query.statement.should eq "SELECT * FROM users LIMIT 2"
    end
  end

  describe "#order_by" do
    it "adds an order clause" do
      query = UserQuery.new.order_by(:name, :asc).query

      query.statement.should eq "SELECT * FROM users ORDER BY name ASC"
    end
  end
end

private def insert_a_user
  LuckyRecord::Repo.run do |db|
    db.exec "INSERT INTO users(name, created_at, updated_at, age, joined_at) VALUES ($1, $2, $3, $4, $5)",
      "Paul",
      Time.now,
      Time.now,
      34,
      Time.now
  end
end
