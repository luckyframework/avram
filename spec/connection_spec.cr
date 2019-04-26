require "./spec_helper"

describe Avram::Connection do
  it "displays a helpful error when failing to connect" do
    conn = Avram::Connection.new("postgres://root:root@localhost:5432/tacoman")
    message = Regex.new("Failed to connect to databse 'tacoman' with username root.")
    expect_raises(Avram::ConnectionError, message) do
      conn.try_connection!
    end
  end
end
