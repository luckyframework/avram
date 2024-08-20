require "../spec_helper"

private class QueryMe < BaseModel
  COLUMN_SQL = %("transactions"."id", "transactions"."created_at", "transactions"."updated_at", "transactions"."small_amount", "transactions"."amount", "transactions"."big_amount")

  table transactions do
    column small_amount : Int16
    column amount : Int32
    column big_amount : Int64
  end
end

# These specs handle all ints: Int16, Int32, Int64
describe "Int::Lucky::Criteria" do
  describe "abs" do
    it "uses ABS" do
      small_amount.abs.eq(4).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM transactions WHERE ABS(\"transactions\".\"small_amount\") = $1", "4"]
      amount.abs.eq(400).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM transactions WHERE ABS(\"transactions\".\"amount\") = $1", "400"]
      big_amount.abs.eq(40000).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM transactions WHERE ABS(\"transactions\".\"big_amount\") = $1", "40000"]
    end
  end
end

private def small_amount
  QueryMe::BaseQuery.new.small_amount
end

private def amount
  QueryMe::BaseQuery.new.amount
end

private def big_amount
  QueryMe::BaseQuery.new.big_amount
end
