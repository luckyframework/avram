require "../../spec_helper"
include CleanupHelper

describe Db::Schema::Dump do
  it "generates a new sql dump file" do
    with_cleanup do
      Db::Schema::Dump.new.print_help_or_call(args: ["structure.sql"])

      filename = "structure.sql"
      File.exists?(filename).should eq true
      File.read(filename).should contain "PostgreSQL database dump"
    end
  end
end
