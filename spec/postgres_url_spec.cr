require "./spec_helper"

describe Avram::PostgresURL do
  it "strips space and newlines from the username" do
    creds = Avram::PostgresURL.build(database: "test", username: " oops\n")

    creds.username.should eq "oops"
  end

  it "raises an InvalidDatabaseNameError when the database name is blank" do
    expect_raises(Avram::InvalidDatabaseNameError) do
      Avram::PostgresURL.parse("")
    end
  end

  describe "parse" do
    it "returns nil when there's nothing to parse" do
      Avram::PostgresURL.parse(nil).should eq nil
    end
  end
end
