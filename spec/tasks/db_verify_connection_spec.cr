require "../spec_helper"

describe Db::VerifyConnection do
  it "throws a helpful error" do
    TestDatabase.temp_config(url: "postgres://eat@joes/crab_shack") do
      expect_raises Exception, /Unable to connect to Postgres for database 'TestDatabase'/ do
        Db::VerifyConnection.new.call
      end
    end
  end
end
