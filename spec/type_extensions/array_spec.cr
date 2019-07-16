require "../spec_helper"

describe "Array" do
  it "parses Array(Bool) from Array(String)" do
    result = Bool::Lucky.parse(["true"])
    result.value.should eq([true])
  end

  it "parses Array(String)" do
    result = String::Lucky.parse(["test"])
    result.value.should eq(["test"])
  end

  it "parses Array(Int32) from Array(String)" do
    result = Int32::Lucky.parse(["10"])
    result.value.should eq([10])
  end

  it "parses Array(Int16) from Array(String)" do
    result = Int16::Lucky.parse(["1"])
    result.value.should eq([1_i16])
  end

  it "parses Array(Int64) from Array(String)" do
    result = Int64::Lucky.parse(["1000"])
    result.value.should eq([1000_i64])
  end

  it "parses Array(UUID) from Array(String)" do
    result = UUID::Lucky.parse(["f51a73d5-bb75-465a-8f8b-d213658dfc63"])
    result.value.should eq([UUID.new("f51a73d5-bb75-465a-8f8b-d213658dfc63")])
  end

  it "parses Array(Time) from Array(String)" do
    result = Time::Lucky.parse(["2019-07-16 14:42:12"])
    time = Time.parse_utc("2019-07-16 14:42:12", "%Y-%m-%d %H:%M:%S")
    result.value.should eq([time])
  end
end
