require "./spec_helper"

private class QueryMe < LuckyRecord::Model
  table users do
    field admin : Bool
  end
end

describe LuckyRecord::BoolType::Criteria do
  describe "is" do
    it "=" do
      admin.is(true).to_sql.should eq ["SELECT * FROM users WHERE admin = $1", "true"]
      admin.is(false).to_sql.should eq ["SELECT * FROM users WHERE admin = $1", "false"]
    end
  end
end

private def admin
  QueryMe::BaseQuery.new.admin
end
