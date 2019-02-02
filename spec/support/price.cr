require "./line_item"

class Price < Avram::Model
  table :prices, primary_key_type: :uuid do
    column in_cents : Int32
    belongs_to line_item : LineItem
  end
end

class PriceQuery < Price::BaseQuery
end
