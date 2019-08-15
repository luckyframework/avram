require "./spec_helper"

describe "Query logging" do
  it "logs if there is a logger and a log level is set" do
    log_io = IO::Memory.new
    logger = Dexter::Logger.new(log_io)
    Avram.temp_config(logger: logger, query_log_level: ::Logger::Severity::INFO) do |settings|
      UserQuery.new.name("Bob").select("*").first?
      log_io.to_s.should contain %(WHERE users.name = $1)
      log_io.to_s.should contain %(["Bob"])
    end
  end

  it "does not log if a logger is set and log level is 'nil'" do
    log_io = IO::Memory.new
    logger = Dexter::Logger.new(log_io)
    Avram.temp_config(logger: logger, query_log_level: nil) do |settings|
      UserQuery.new.name("Bob").first?
      log_io.to_s.should eq("")
    end
  end
end
