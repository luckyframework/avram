require "../spec_helper"

private class QueryMe < BaseModel
  COLUMN_SQL = "users.id, users.created_at, users.updated_at, users.age, users.nickname"

  table users do
    column age : Int32
    column nickname : String?
  end
end

describe Avram::Criteria do
  describe "eq" do
    it "uses =" do
      age.eq(30).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age = $1", "30"]
    end
  end

  describe "nilable_eq" do
    it "uses =" do
      # Need to do this so that we get a nilable type
      nilable_age = 30.as(Int32?)
      age.nilable_eq(nilable_age).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age = $1", "30"]
    end

    it "uses 'IS NULL' for comparisons to nil" do
      # Need to do this so that we get a nilable type, but not just Nil
      nilable = [nil, "name"].first
      nickname.nilable_eq(nilable).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.nickname IS NULL"]
    end
  end

  describe "is_nil" do
    it "uses IS NULL" do
      nickname.is_nil.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.nickname IS NULL"]
    end
  end

  describe "is_not_nil" do
    it "uses IS NOT NULL" do
      nickname.is_not_nil.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.nickname IS NOT NULL"]
    end
  end

  describe "gt" do
    it "uses >" do
      age.gt("30").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age > $1", "30"]
    end
  end

  describe "gte" do
    it "uses >=" do
      age.gte("30").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age >= $1", "30"]
    end
  end

  describe "lt" do
    it "uses <" do
      age.lt("30").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age < $1", "30"]
    end
  end

  describe "lte" do
    it "uses <=" do
      age.lte("30").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age <= $1", "30"]
    end
  end

  describe "not" do
    it "negates the following criteria" do
      age.not.gt("3").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age <= $1", "3"]
    end

    it "resets after having negated once" do
      age.not.gt("3").age.eq("20").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.age <= $1 AND users.age = $2", "3", "20"]
    end
  end
end

private def age
  QueryMe::BaseQuery.new.age
end

private def nickname
  QueryMe::BaseQuery.new.nickname
end
