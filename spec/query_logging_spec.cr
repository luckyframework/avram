require "./spec_helper"

describe "Query logging" do
  it "logs the statement and args" do
    Avram::QueryLog.dexter.temp_config do |log_io|
      UserQuery.new.name("Bob").select("*").first?
      log_io.to_s.should contain %(WHERE users.name = $1)
      log_io.to_s.should contain %(["Bob"])
    end
  end
end
