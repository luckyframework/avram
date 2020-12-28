require "../spec_helper"
include CleanupHelper

describe Db::Schema::Dump do
  it "generates a new sql dump file" do
    with_cleanup do
      Db::Schema::Dump.new("structure.sql").run_task

      filename = "structure.sql"
      File.exists?(filename).should eq true
      File.read(filename).should contain "PostgreSQL database dump"
    end
  end
end
