require "../spec_helper"

describe Avram::Credentials do
  it "strips space and newlines from the username" do
    creds = Avram::Credentials.new(database: "test", username: " oops\n")

    creds.username.should eq "oops"
  end

  it "raises an InvalidDatabaseNameError when the database name is blank" do
    expect_raises(Avram::InvalidDatabaseNameError) do
      Avram::Credentials.parse("")
    end
  end

  describe "parse?" do
    it "returns nil when there's nothing to parse" do
      Avram::Credentials.parse?(nil).should eq nil
    end

    it "returns a proper url when provided a connection string" do
      conn = "postgres://user@/test?initial_pool_size=5&retry_attempts=4"
      creds = Avram::Credentials.parse?(conn)

      creds.as(Avram::Credentials).url.should eq conn
    end
  end

  describe "parse" do
    it "returns a proper url when provided a connection string" do
      conn = "postgres://user@/test?initial_pool_size=5&retry_attempts=4"
      creds = Avram::Credentials.parse(conn)

      creds.url.should eq conn
    end
  end

  it "builds a unix socket URL" do
    creds = Avram::Credentials.new(database: "test_db")

    creds.url.should eq "postgres:///test_db"
  end

  it "allows for query string options" do
    creds = Avram::Credentials.new(
      database: "test",
      username: "user",
      query: "initial_pool_size=5&retry_attempts=4")

    creds.url.should eq "postgres://user@/test?initial_pool_size=5&retry_attempts=4"
  end

  it "has access to the url without the query params" do
    creds = Avram::Credentials.new(
      database: "test",
      username: "user",
      query: "initial_pool_size=5&retry_attempts=4")

    creds.url_without_query_params.should eq "postgres://user@/test"
    creds.url.should eq "postgres://user@/test?initial_pool_size=5&retry_attempts=4"
  end

  describe "void" do
    it "returns an unused url" do
      creds = Avram::Credentials.void

      creds.url.should eq "postgres:///unused"
    end
  end
end
