require "../../spec_helper"

describe "Bytes" do
  it "parses Bytes from String" do
    result = Bytes.adapter.parse("10")
    result.value.should eq(10)
  end


end
