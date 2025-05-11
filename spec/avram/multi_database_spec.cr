require "../spec_helper"

private class ModelWithBadDatabase < BaseModel
  table do
  end

  # Use a different database for this fake model
  def self.database
    DatabaseWithIncorrectSettings
  end
end

private class BaseModelWithSeparateReadWrite < Avram::Model
  table :users do
  end

  class_getter read_count : Int32 = 0
  class_getter write_count : Int32 = 0

  def self.read_database : Avram::Database.class
    @@read_count += 1
    TestDatabase
  end

  def self.write_database : Avram::Database.class
    @@write_count += 1
    TestDatabase
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

  context "when read and write are separate DBs" do
    it "uses the read_database" do
      BaseModelWithSeparateReadWrite::BaseQuery.new.select_count
      BaseModelWithSeparateReadWrite.read_count.should eq(1)
    end

    it "uses the write_database" do
      BaseModelWithSeparateReadWrite::BaseQuery.new.delete
      BaseModelWithSeparateReadWrite.write_count.should eq(1)
    end
  end
end
