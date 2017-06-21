require "../spec_helper"

describe LuckyRecord::Query do
  describe "#first" do
    it "gets the first row from the database" do
      insert_a_user
      UserRows.new.first.name.should eq "Paul"
    end
  end

  describe "#find" do
    it "gets the record with the given id" do
      insert_a_user
      user = UserRows.new.first

      UserRows.new.find(user.id).should eq user
    end
  end

  describe "#where" do
    it "chains wheres" do
      query = UserRows.new.where(:first_name, "Paul").where(:last_name, "Smith").query

      query.statement.should eq "SELECT * FROM users WHERE first_name = $1 AND last_name = $2"
      query.args.should eq ["Paul", "Smith"]
    end

    it "handles int" do
      query = UserRows.new.where(:id, 1).query

      query.statement.should eq "SELECT * FROM users WHERE id = $1"
      query.args.should eq ["1"]
    end
  end

  describe "#limit" do
    it "adds a limit clause" do
      query = UserRows.new.limit(2).query

      query.statement.should eq "SELECT * FROM users LIMIT 2"
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
