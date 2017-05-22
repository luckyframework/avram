require "../spec_helper"

private class QueryMe < LuckyRecord::Schema
  table :users do
    field age : NothingExtra
  end
end

class LuckyRecord::NothingExtraType < LuckyRecord::Type
  alias BaseType = Int32

  class Criteria(T) < LuckyRecord::Criteria(T)
  end
end

describe LuckyRecord::Criteria do
  describe "is" do
    it "uses =" do
      age.is(30).to_sql.should eq ["SELECT * FROM users WHERE age = $1", "30"]
    end
  end

  describe "is_not" do
    it "uses !=" do
      age.is_not(30).to_sql.should eq ["SELECT * FROM users WHERE age != $1", "30"]
    end
  end

  describe "gt" do
    it "uses >" do
      age.gt("30").to_sql.should eq ["SELECT * FROM users WHERE age > $1", "30"]
    end
  end

  describe "gte" do
    it "uses >=" do
      age.gte("30").to_sql.should eq ["SELECT * FROM users WHERE age >= $1", "30"]
    end
  end

  describe "lt" do
    it "uses <" do
      age.lt("30").to_sql.should eq ["SELECT * FROM users WHERE age < $1", "30"]
    end
  end

  describe "lte" do
    it "uses <=" do
      age.lte("30").to_sql.should eq ["SELECT * FROM users WHERE age <= $1", "30"]
    end
  end
end

private def age
  QueryMe::BaseRows.new.age
end
