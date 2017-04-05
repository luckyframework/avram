require "../spec_helper"

describe "LuckyRecord::Query" do
  it "selects all" do
    new_query.to_sql.should eq "SELECT * FROM users"
  end

  it "can be limited" do
    query = new_query.limit(1)
    query.to_sql.should eq "SELECT * FROM users LIMIT 1"
  end

  it "handles simple where comparison" do
    query = new_query.where_eq(:name, "'Paul'")
    query.to_sql.should eq "SELECT * FROM users WHERE name = 'Paul'"
  end

  it "handles >" do
    query = new_query.where_gt(:age, 20)
    query.to_sql.should eq "SELECT * FROM users WHERE age > 20"
  end

  it "handles >=" do
    query = new_query.where_gte(:age, 20)
    query.to_sql.should eq "SELECT * FROM users WHERE age >= 20"
  end

  it "handles <" do
    query = new_query.where_lt(:age, 20)
    query.to_sql.should eq "SELECT * FROM users WHERE age < 20"
  end

  it "handles <=" do
    query = new_query.where_lte(:age, 20)
    query.to_sql.should eq "SELECT * FROM users WHERE age <= 20"
  end

  it "chains wheres" do
    query = new_query.where_gte(:age, 20).where_lte(:age, 100)
    query.to_sql.should eq "SELECT * FROM users WHERE age >= 20 AND age <= 100"
  end
end

private def new_query
  LuckyRecord::Query.new(table: :users)
end
