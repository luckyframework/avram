require "../spec_helper"

describe Db::Schema::Dump do
  it "generates a new sql dump file" do
    Db::Schema::Dump.new("tmp/structure.sql").call

    filename = "tmp/structure.sql"
    File.exists?(filename).should eq true
    File.read(filename).should contain "PostgreSQL database dump"
  end
end
