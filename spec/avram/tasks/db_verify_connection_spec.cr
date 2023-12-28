require "../../spec_helper"

describe Db::VerifyConnection do
  it "runs a test connection" do
    task = Db::VerifyConnection.new
    task.output = IO::Memory.new
    task.run_task
    task.output.to_s.should contain "Connection verified"
  end

  it "throws a helpful error" do
    creds = Avram::Credentials.parse("postgres://eat@joes/crab_shack")
    TestDatabase.temp_config(credentials: creds) do
      expect_raises Exception, /Unable to connect to Postgres for database 'TestDatabase'/ do
        task = Db::VerifyConnection.new.run_task
      end
    end
  end
end
