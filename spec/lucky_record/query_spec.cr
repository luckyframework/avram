require "../spec_helper"

describe "LuckyRecord::Query" do
  it "selects all" do
    new_query.to_sql.should eq "SELECT * FROM users"
  end

  it "can be limited" do
    query = new_query.limit(1)
    query.to_sql.should eq "SELECT * FROM users LIMIT 1"
  end

  it "accepts where clauses" do
    query = new_query
      .where(LuckyRecord::Where::Equal.new(:name, "'Paul'"))
      .where(LuckyRecord::Where::GreaterThan.new(:age, "20"))
    query.to_sql.should eq "SELECT * FROM users WHERE name = 'Paul' AND age > 20"
  end
end

private def new_query
  LuckyRecord::Query.new(table: :users)
end
