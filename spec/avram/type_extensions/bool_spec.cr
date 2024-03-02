require "../../spec_helper"

describe Bool do
  describe "blank?" do
    it "returns false" do
      true.blank?.should be_false
    end
  end

  describe "parsing value" do
    it "works with correct strings" do
      correct_values = %w(true 1 false 0)
      expected = [true, true, false, false]
      correct_values.each_with_index do |val, ix|
        Bool.adapter.parse(val).value.should eq expected[ix]
      end
    end

    it "fails with malformed strings" do
      wrong_value = "fAl;se"
      expect_raises(Avram::FailedCastError) {
        Bool.adapter.parse(wrong_value).value
      }
    end
  end
end
