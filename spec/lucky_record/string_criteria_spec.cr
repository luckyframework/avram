require "../spec_helper"

private class QueryMe < LuckyRecord::Schema
  table :users do
    field name : String
  end
end

describe LuckyRecord::StringType::Criteria do
  describe "like" do
    it "uses LIKE" do
      name.like("elon").to_sql.should eq ["SELECT * FROM users WHERE name LIKE $1", "elon"]
    end
  end

  describe "ilike" do
    it "uses LIKE" do
      name.ilike("elon").to_sql.should eq ["SELECT * FROM users WHERE name ILIKE $1", "elon"]
    end
  end

  describe "lower" do
    it "uses LOWER" do
      name.lower.is("elon").to_sql.should eq ["SELECT * FROM users WHERE LOWER(name) = $1", "elon"]
    end
  end

  describe "upper" do
    it "uses UPPER" do
      name.upper.is("elon").to_sql.should eq ["SELECT * FROM users WHERE UPPER(name) = $1", "elon"]
    end
  end
end

private def name
  QueryMe::BaseRows.new.name
end
