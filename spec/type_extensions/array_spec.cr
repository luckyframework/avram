require "../spec_helper"

describe "Array" do
  it "parses Array(Bool) from Array(String)" do
    result = Bool::Lucky._parse_attribute(["true"])
    result.value.should eq([true])
  end

  it "parses Array(String)" do
    result = String::Lucky._parse_attribute(["test"])
    result.value.should eq(["test"])
  end

  it "parses Array(Int32) from Array(String)" do
    result = Int32::Lucky._parse_attribute(["10"])
    result.value.should eq([10])
  end

  it "parses Array(Int16) from Array(String)" do
    result = Int16::Lucky._parse_attribute(["1"])
    result.value.should eq([1_i16])
  end

  it "parses Array(Int64) from Array(String)" do
    result = Int64::Lucky._parse_attribute(["1000"])
    result.value.should eq([1000_i64])
  end

  it "parses Array(Float64) from Array(String)" do
    result = Float64::Lucky._parse_attribute(["3.1415"])
    result.value.should eq([3.1415])
  end
end
