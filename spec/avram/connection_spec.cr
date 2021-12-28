require "../spec_helper"

describe Avram::Connection do
  it "displays a helpful error when failing to connect" do
    conn = Avram::Connection.new("postgres://root:root@localhost:5432/tacoman", TestDatabase)
    message = Regex.new("TestDatabase: Failed to connect to database 'tacoman' with username 'root'.")
    expect_raises(Avram::ConnectionError, message) do
      conn.open
    end
  end

  it "suggests trying a password when no password supplied and connection fails" do
    conn = Avram::Connection.new("postgres://root@localhost:5432/tacoman", TestDatabase)
    message = Regex.new("You didn't supply a password, did you mean to?")
    expect_raises(Avram::ConnectionError, message) do
      conn.open
    end
  end
end
