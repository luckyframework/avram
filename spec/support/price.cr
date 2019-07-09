class Price < BaseModel
  skip_default_columns

  table do
    primary_key id : UUID
    timestamps
    column in_cents : Int32
    belongs_to line_item : LineItem
  end
end

class PriceQuery < Price::BaseQuery
end
