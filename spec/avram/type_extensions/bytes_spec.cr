require "../../spec_helper"

describe "Bytes" do
  it "parses Bytes from String" do
    result = Bytes.adapter.parse("10")
    result.value.should eq(Bytes[49, 48])
  end

  it "returns SuccessfulCast for Bytes" do
    result = Bytes.adapter.parse(Bytes[10, 10, 10])
    result.should be_a(Avram::Type::SuccessfulCast(Bytes))
    result.value.should eq(Bytes[10, 10, 10])
  end
end
