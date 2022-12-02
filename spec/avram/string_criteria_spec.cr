require "../spec_helper"

private class QueryMe < BaseModel
  COLUMN_SQL = "users.id, users.created_at, users.updated_at, users.name"

  table users do
    column name : String
  end
end

describe String::Lucky::Criteria do
  describe "like" do
    it "uses LIKE" do
      name.like("elon").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.name LIKE $1", "elon"]
    end
  end

  describe "ilike" do
    it "uses LIKE" do
      name.ilike("elon").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.name ILIKE $1", "elon"]
    end
  end

  describe "lower" do
    it "uses LOWER" do
      name.lower.eq("elon").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE LOWER(users.name) = $1", "elon"]
    end
  end

  describe "upper" do
    it "uses UPPER" do
      name.upper.eq("elon").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE UPPER(users.name) = $1", "elon"]
    end
  end

  describe "trim" do
    it "uses TRIM" do
      name.trim.eq("elon").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE TRIM(users.name) = $1", "elon"]
    end
  end

  describe "not" do
    describe "with chained criteria" do
      it "negates the following criteria" do
        name.not.like("pete").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.name NOT LIKE $1", "pete"]
        name.not.ilike("pete").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.name NOT ILIKE $1", "pete"]
      end

      it "resets after having negated once" do
        name.not.like("pete").name.eq("sarah").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.name NOT LIKE $1 AND users.name = $2", "pete", "sarah"]
        name.not.ilike("pete").name.eq("sarah").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.name NOT ILIKE $1 AND users.name = $2", "pete", "sarah"]
      end
    end
  end
end

private def name
  QueryMe::BaseQuery.new.name
end
