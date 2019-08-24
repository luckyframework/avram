require "../spec_helper"

describe Db::Schema::Dump do
  it "generates a new sql dump file" do
    Db::Schema::Dump.new.call

    filename = Dir.entries(Dir.current).find { |e| e =~ /lucky_avram_dev_dump/ }.to_s
    File.exists?(filename).should eq true
    File.read(filename).should contain "PostgreSQL database dump"
    File.delete(filename)
  end
end
