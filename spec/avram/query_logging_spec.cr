require "../spec_helper"

describe "Query logging" do
  it "logs the statement and args" do
    Avram::QueryLog.dexter.temp_config do |log_io|
      UserQuery.new.name("Bob").first?
      log_io.to_s.should contain %(WHERE users.name = $1)
      log_io.to_s.should contain %(Bob)
      log_io.to_s.should contain %(duration)
    end
  end

  it "does not log truncate statements" do
    Avram::QueryLog.dexter.temp_config do |log_io|
      TestDatabase.truncate
      log_io.to_s.should_not contain("TRUNCATE TABLE")
    end
  end

  it "logs failed queries" do
    Avram::FailedQueryLog.dexter.temp_config do |log_io|
      expect_raises(PQ::PQError) do
        TestDatabase.scalar "NOT VALID SORRY"
      end
      log_io.to_s.should contain("syntax error at or near")
      log_io.to_s.should contain("NOT VALID SORRY")
      # Filter args so failed queries can be safely logged in production
      log_io.to_s.should contain("[FILTERED]")
    end
  end
end
