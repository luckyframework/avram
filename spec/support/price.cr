require "./line_item"

class Price < Avram::Model
  skip_default_columns

  table :prices do
    primary_key id : UUID
    timestamps
    column in_cents : Int32
    belongs_to line_item : LineItem
  end
end

class PriceQuery < Price::BaseQuery
end
