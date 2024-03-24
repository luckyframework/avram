require "../spec_helper"

private class QueryMe < BaseModel
  COLUMN_SQL = "users.id, users.created_at, users.updated_at, users.preferences"

  table users do
    column preferences : JSON::Any
  end
end

describe JSON::Any::Lucky::Criteria do
  describe "has_key" do
    it "?" do
      preferences.has_key("theme").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.preferences ? $1", "theme"]
    end

    it "negates with NOT()" do
      preferences.not.has_key("theme").to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE NOT(users.preferences ? $1)", "theme"]
    end
  end

  describe "has_any_keys" do
    it "?|" do
      preferences.has_any_keys(["theme", "style"]).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.preferences ?| $1", ["theme", "style"]]
    end

    it "negates with NOT()" do
      preferences.not.has_any_keys(["theme", "style"]).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE NOT(users.preferences ?| $1)", ["theme", "style"]]
    end
  end

  describe "has_all_keys" do
    it "?&" do
      preferences.has_all_keys(["theme", "style"]).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.preferences ?& $1", ["theme", "style"]]
    end

    it "negates with NOT()" do
      preferences.not.has_all_keys(["theme", "style"]).to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE NOT(users.preferences ?& $1)", ["theme", "style"]]
    end
  end

  describe "includes" do
    it "@>" do
      json = JSON::Any.new({"theme" => JSON::Any.new("dark")})
      critera = preferences.includes(json)
      critera.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.preferences @> $1", "{\"theme\":\"dark\"}"]
    end

    it "negates with NOT()" do
      json = JSON::Any.new({"theme" => JSON::Any.new("dark")})
      critera = preferences.not.includes(json)
      critera.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE NOT(users.preferences @> $1)", "{\"theme\":\"dark\"}"]
    end
  end

  describe "in" do
    it "<@" do
      json = JSON::Any.new({"theme" => JSON::Any.new("dark"), "style" => JSON::Any.new("cyberpunk"), "version" => JSON::Any.new(2i64)})
      critera = preferences.in(json)
      critera.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.preferences <@ $1", "{\"theme\":\"dark\",\"style\":\"cyberpunk\",\"version\":2}"]
    end

    it "negates with NOT()" do
      json = JSON::Any.new({"theme" => JSON::Any.new("dark"), "style" => JSON::Any.new("cyberpunk"), "version" => JSON::Any.new(2i64)})
      critera = preferences.not.in(json)
      critera.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE NOT(users.preferences <@ $1)", "{\"theme\":\"dark\",\"style\":\"cyberpunk\",\"version\":2}"]
    end
  end
end

private def preferences
  QueryMe::BaseQuery.new.preferences
end
