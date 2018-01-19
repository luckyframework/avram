require "./spec_helper"

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

  it "can be offset" do
    query = new_query.offset(1)
    query.statement.should eq "SELECT * FROM users OFFSET 1"
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

  it "accepts raw where clauses" do
    query = new_query
      .raw_where(LuckyRecord::Where::Raw.new("name = ?", "Mikias"))
      .raw_where(LuckyRecord::Where::Raw.new("age > ?", 26))
      .limit(1)
    query.statement.should eq "SELECT * FROM users WHERE name = 'Mikias' AND age > 26 LIMIT 1"
    query.args.empty?.should be_true
  end

  it "can be ordered" do
    query = new_query
      .order_by(:name, :asc)
      .order_by(:birthday, :asc)
      .order_by(:email, :desc)
    query.statement.should eq "SELECT * FROM users ORDER BY name, birthday ASC, email DESC"
    query.args.should eq [] of String

    query = new_query
      .order_by(:name, :asc)
    query.statement.should eq "SELECT * FROM users ORDER BY name ASC"
  end

  it "can select distinct" do
    query = new_query.distinct
    query.statement.should eq "SELECT DISTINCT * FROM users"
    query.args.should eq [] of String
  end

  describe "updating" do
    it "inserts with a hash of String" do
      params = {:first_name => "Paul", :last_name => nil}
      query = LuckyRecord::QueryBuilder
        .new(table: :users)
        .where(LuckyRecord::Where::Equal.new(:id, "1"))
        .limit(1)

      query.statement_for_update(params).should eq "UPDATE users SET first_name = $1, last_name = $2 WHERE id = $3 LIMIT 1 RETURNING *"
      query.args_for_update(params).should eq ["Paul", nil, "1"]
    end
  end

  it "can be counted" do
    query = LuckyRecord::QueryBuilder
      .new(table: :users)
      .count

    query.statement.should eq "SELECT COUNT(*) FROM users"
    query.args.should eq [] of String
  end

  describe "#select" do
    it "specifies columns to be selected" do
      query = LuckyRecord::QueryBuilder
        .new(table: :users)
        .select([:name, :age])

      query.statement.should eq "SELECT users.name, users.age FROM users"
    end
  end

  it "can be joined" do
    query = LuckyRecord::QueryBuilder
      .new(table: :users)
      .join(LuckyRecord::Join::Inner.new(:users, :posts))
      .limit(1)

    query.statement.should eq "SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id LIMIT 1"
  end

  describe "#reverse_order" do
    it "reverses the order of the query" do
      query = LuckyRecord::QueryBuilder
        .new(table: :users)
        .order_by(:id, :asc)
        .reverse_order

      query.statement.should eq "SELECT * FROM users ORDER BY id DESC"
    end

    it "reverses both directions" do
      query = LuckyRecord::QueryBuilder
        .new(table: :users)
        .order_by(:id, :asc)
        .order_by(:name, :desc)
        .reverse_order

      query.statement.should eq "SELECT * FROM users ORDER BY name ASC, id DESC"

      LuckyRecord::Repo.run do |db|
        db.exec query.statement
      end
    end

    it "does nothing if there is no order" do
      query = LuckyRecord::QueryBuilder
        .new(table: :users)
        .reverse_order

      query.statement.should eq "SELECT * FROM users"
    end
  end

  describe "#ordered" do
    it "returns true if the query is ordered" do
      query = LuckyRecord::QueryBuilder
        .new(table: :users)
        .order_by(:id, :asc)

      query.ordered?.should eq true
    end

    it "returns false if the query is not ordered" do
      query = LuckyRecord::QueryBuilder
        .new(table: :users)

      query.ordered?.should eq false
    end
  end
end

private def new_query
  LuckyRecord::QueryBuilder.new(table: :users)
end
