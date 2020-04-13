require "./spec_helper"

describe "Query logging" do
  it "logs the statement and args" do
    LogHelper.temp_override(Avram::QueryLog) do |log_io|
      UserQuery.new.name("Bob").select("*").first?
      log_io.to_s.should contain %(WHERE users.name = $1)
      log_io.to_s.should contain %(["Bob"])
    end
  end
end
