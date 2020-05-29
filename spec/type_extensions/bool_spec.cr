require "../spec_helper"

describe Bool do
  describe "blank?" do
    it "returns false" do
      true.blank?.should be_false
    end
  end

  describe "parsing" do
    it "parses empty string as nil" do
      parse("").should be_a(Avram::Type::SuccessfulCast(Nil))
    end

    it "parses strings" do
      parse("true").value.should eq(true)
      parse("1").value.should eq(true)
      parse("false").value.should eq(false)
      parse("0").value.should eq(false)
    end
  end
end

private def parse(value)
  Bool::Lucky.parse(value)
end
