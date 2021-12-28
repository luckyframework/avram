require "../spec_helper"

private class ModelWithBadDatabase < BaseModel
  table do
  end

  # Use a different database for this fake model
  def self.database
    DatabaseWithIncorrectSettings
  end
end

describe "Configuring and connecting to different databases" do
  it "tries to connect to the configured database" do
    # It will fail to connect which is what we expect since we configured
    # a database with an incorrect URL
    #
    # If it does not raise an error then the connection is good,
    # which is not what we configured
    expect_raises Avram::ConnectionError do
      ModelWithBadDatabase::BaseQuery.new.select_count
    end
  end
end
