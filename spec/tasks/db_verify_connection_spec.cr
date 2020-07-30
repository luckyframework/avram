require "../spec_helper"

describe Db::VerifyConnection do
  it "throws a helpful error" do
    creds = Avram::Credentials.parse?("postgres://eat@joes/crab_shack").not_nil!
    TestDatabase.temp_config(credentials: creds) do
      expect_raises Exception, /Unable to connect to Postgres for database 'TestDatabase'/ do
        Db::VerifyConnection.new.call
      end
    end
  end
end
