require "../spec_helper"

describe LuckyRecord::Rows do
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
    it "filters by each key and value" do
      sql = UserRows.new.where({first_name: "Paul", last_name: "Smith"}).to_sql

      sql.should eq "SELECT * FROM users WHERE first_name = 'Paul' AND last_name = 'Smith'"
    end

    it "chains wheres" do
      sql = UserRows.new.where({first_name: "Paul"}).where({last_name: "Smith"}).to_sql

      sql.should eq "SELECT * FROM users WHERE first_name = 'Paul' AND last_name = 'Smith'"
    end

    it "escapes values" do
      sql = UserRows.new.where({first_name: %(what's your "name")}).to_sql

      sql.should eq %(SELECT * FROM users WHERE first_name = 'what''s your \"name\"')
    end

    it "handles int" do
      sql = UserRows.new.where({id: 1}).to_sql

      sql.should eq %(SELECT * FROM users WHERE id = 1)
    end
  end

  describe "#limit" do
    it "adds a limit clause" do
      sql = UserRows.new.limit(2).to_sql

      sql.should eq %(SELECT * FROM users LIMIT 2)
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
