require "./spec_helper"

private class QueryMe < LuckyRecord::Model
  table users do
    field activated_at : Time
  end
end

describe LuckyRecord::TimeType::Criteria do
  describe "is" do
    it "=" do
      now = Time.now
      activated_at.is(now).to_sql.should eq ["SELECT * FROM users WHERE activated_at = $1", now.to_s]
    end
  end
end

private def activated_at
  QueryMe::BaseQuery.new.activated_at
end
