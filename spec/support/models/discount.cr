class Discount < BaseModel
  skip_default_columns

  table do
    primary_key id : String, Random::Secure.hex
    timestamps
    column description : String
    column in_cents : Int32
    belongs_to line_item : LineItem
  end
end

class DiscountQuery < Discount::BaseQuery
end
