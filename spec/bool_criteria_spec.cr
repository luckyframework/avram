require "./spec_helper"

private class QueryMe < Avram::Model
  COLUMNS = "users.id, users.created_at, users.updated_at, users.admin"

  table users do
    column admin : Bool
  end
end

describe Bool::Lucky::Criteria do
  describe "is" do
    it "=" do
      admin.is(true).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.admin = $1", "true"]
      admin.is(false).to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.admin = $1", "false"]
    end
  end
end

private def admin
  QueryMe::BaseQuery.new.admin
end
