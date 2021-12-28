require "../../spec_helper"

describe Bool do
  describe "blank?" do
    it "returns false" do
      true.blank?.should be_false
    end
  end
end
