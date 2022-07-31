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

  describe "blank?" do
    it "returns true" do
      result = Bytes.adapter.parse(Bytes.empty)
      result.value.blank?.should eq(true)
    end

    it "returns false" do
      result = Bytes.adapter.parse("100".to_slice)
      result.value.blank?.should eq(false)
    end
  end
end
