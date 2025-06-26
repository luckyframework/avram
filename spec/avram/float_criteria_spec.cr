require "../spec_helper"

private class QueryMe < BaseModel
  COLUMN_SQL = %("purchases"."id", "purchases"."created_at", "purchases"."updated_at", "purchases"."amount")

  table purchases do
    column amount : Float64
  end
end

describe Float64::Lucky::Criteria do
  describe "abs" do
    it "uses ABS" do
      amount.abs.eq(39.99).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM purchases WHERE ABS(\"purchases\".\"amount\") = $1", "39.99"]
    end
  end

  describe "ceil" do
    it "uses CEIL" do
      amount.ceil.eq(40.0).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM purchases WHERE CEIL(\"purchases\".\"amount\") = $1", "40.0"]
    end
  end

  describe "floor" do
    it "uses FLOOR" do
      amount.floor.eq(39.0).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM purchases WHERE FLOOR(\"purchases\".\"amount\") = $1", "39.0"]
    end
  end
end

private def amount
  QueryMe::BaseQuery.new.amount
end
