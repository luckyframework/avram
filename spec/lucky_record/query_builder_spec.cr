require "../spec_helper"

describe "LuckyRecord::QueryBuilder" do
  it "selects all" do
    new_query.statement.should eq "SELECT * FROM users"
    new_query.args.should eq [] of String
  end

  it "can be limited" do
    query = new_query.limit(1)
    query.statement.should eq "SELECT * FROM users LIMIT 1"
    query.args.should eq [] of String
  end

  it "accepts where clauses and limits" do
    query = new_query
      .where(LuckyRecord::Where::Equal.new(:name, "Paul"))
      .where(LuckyRecord::Where::GreaterThan.new(:age, "20"))
      .limit(1)
    query.statement.should eq "SELECT * FROM users WHERE name = $1 AND age > $2 LIMIT 1"
    query.args.should eq ["Paul", "20"]
  end

  describe "updating" do
    it "inserts with a hash of String" do
      params = {:first_name => "Paul", :last_name => "Smith"}
      query = LuckyRecord::QueryBuilder
        .new(table: :users)
        .where(LuckyRecord::Where::Equal.new(:id, "1"))
        .limit(1)

      query.statement_for_update(params).should eq "UPDATE users SET first_name = $1, last_name = $2 WHERE id = $3 LIMIT 1 RETURNING *"
      query.args_for_update(params).should eq ["Paul", "Smith", "1"]
    end
  end
end

private def new_query
  LuckyRecord::QueryBuilder.new(table: :users)
end
