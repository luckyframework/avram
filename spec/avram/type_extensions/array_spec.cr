require "../../spec_helper"

describe "Array" do
  it "parses Array(Bool) from Array(String)" do
    result = Bool.adapter.parse(["true"])
    result.value.should eq([true])
  end

  it "parses Array(String)" do
    result = String.adapter.parse(["test"])
    result.value.should eq(["test"])
  end

  it "parses Array(Int32) from Array(String)" do
    result = Int32.adapter.parse(["10"])
    result.value.should eq([10])
  end

  it "parses Array(Int16) from Array(String)" do
    result = Int16.adapter.parse(["1"])
    result.value.should eq([1_i16])
  end

  it "parses Array(Int64) from Array(String)" do
    result = Int64.adapter.parse(["1000"])
    result.value.should eq([1000_i64])
  end

  it "parses Array(Float64) from Array(String)" do
    result = Float64.adapter.parse(["3.1415"])
    result.value.should eq([3.1415])
  end

  it "parses Array(UUID) from Array(String)" do
    result = UUID.adapter.parse(["b7e99d07-22c4-497d-a014-7cc8d3a7b23a"])
    result.value.should eq([UUID.new("b7e99d07-22c4-497d-a014-7cc8d3a7b23a")])
  end
end
