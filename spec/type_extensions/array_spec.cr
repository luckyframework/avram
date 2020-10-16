require "../spec_helper"

describe "Array" do
  it "parses Array(Bool) from Array(String)" do
    result = Bool::Lucky.parse!(["true"])
    result.should eq([true])
  end

  it "parses Array(String)" do
    result = String::Lucky.parse!(["test"])
    result.should eq(["test"])
  end

  it "parses Array(Int32) from Array(String)" do
    result = Int32::Lucky.parse!(["10"])
    result.should eq([10])
  end

  it "parses Array(Int16) from Array(String)" do
    result = Int16::Lucky.parse!(["1"])
    result.should eq([1_i16])
  end

  it "parses Array(Int64) from Array(String)" do
    result = Int64::Lucky.parse!(["1000"])
    result.should eq([1000_i64])
  end

  it "parses Array(Float64) from Array(String)" do
    result = Float64::Lucky.parse(["3.1415"])
    result.value.should eq([3.1415])
  end
end
