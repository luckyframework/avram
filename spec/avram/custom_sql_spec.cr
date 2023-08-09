require "../spec_helper"

describe "Custom SQL" do
  describe "PG::NumericFloatConverter extension" do
    it "converts PG::Numeric to Float64" do
      PriceFactory.create(&.in_cents(399).line_item_id(LineItemFactory.create.id))
      CustomPriceQuery.total.should eq(3.99)
    end
  end
end
