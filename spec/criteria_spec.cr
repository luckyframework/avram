require "./spec_helper"

private class QueryMe < Avram::Model
  COLUMNS = "users.id, users.created_at, users.updated_at, users.age, users.nickname"

  table users do
    column age : Int32
    column nickname : String?
  end
end

describe Avram::Criteria do
  describe "is" do
    it "uses =" do
      age.is(30).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age = $1", "30"]
    end
  end

  describe "is?" do
    it "uses =" do
      age.is?(30).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age = $1", "30"]
    end

    it "uses 'IS NULL' for comparisons to nil" do
      nickname.is?(nil).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.nickname IS NULL"]
    end
  end

  describe "is_not" do
    it "uses !=" do
      age.is_not(30).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age != $1", "30"]
    end
  end

  describe "is_not?" do
    it "uses !=" do
      age.is_not?(30).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age != $1", "30"]
    end

    it "uses 'IS NOT NULL' for comparisons to nil" do
      nickname.is_not?(nil).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.nickname IS NOT NULL"]
    end
  end

  describe "gt" do
    it "uses >" do
      age.gt("30").to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age > $1", "30"]
    end
  end

  describe "gte" do
    it "uses >=" do
      age.gte("30").to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age >= $1", "30"]
    end
  end

  describe "lt" do
    it "uses <" do
      age.lt("30").to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age < $1", "30"]
    end
  end

  describe "lte" do
    it "uses <=" do
      age.lte("30").to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age <= $1", "30"]
    end
  end

  describe "not" do
    describe "without chained criteria" do
      it "negates to not equal" do
        age.not("30").to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age != $1", "30"]
      end
    end

    describe "with chained criteria" do
      it "negates the following criteria" do
        age.not.gt("3").to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age <= $1", "3"]
      end

      it "resets after having negated once" do
        age.not.gt("3").age.is("20").to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.age <= $1 AND users.age = $2", "3", "20"]
      end
    end
  end
end

private def age
  QueryMe::BaseQuery.new.age
end

private def nickname
  QueryMe::BaseQuery.new.nickname
end
