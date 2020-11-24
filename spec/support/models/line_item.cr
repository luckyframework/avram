class LineItem < BaseModel
  skip_default_columns

  table do
    primary_key id : UUID
    timestamps
    column name : String
    has_one price : Price?
    has_many scans : Scan
    has_many line_items_products : LineItemProduct
    has_many associated_products : Product, through: [:line_items_products, :product]
  end
end

class LineItemQuery < LineItem::BaseQuery
end
