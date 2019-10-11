require "../spec_helper"

describe "Int32" do
  it "parses Int32 from String" do
    result = Int32::Lucky.parse("10")
    result.value.should eq(10)
  end

  it "parses Int32 from Int64" do
    result = Int32::Lucky.parse(400_i64)
    result.value.should eq(400)
  end

  it "returns FaileCast when overflow from Int64 to Int32" do
    result = Int32::Lucky.parse(2147483648)
    result.value.should eq(nil)
  end
end
