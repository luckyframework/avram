class LineItem < Avram::Model
  skip_default_columns

  table do
    primary_key id : UUID
    timestamps
    column name : String
    has_one price : Price?
    has_many scans : Scan
    has_many line_items_products : LineItemProduct
    has_many products : Product, through: :line_items_products
  end
end

class LineItemQuery < LineItem::BaseQuery
end
