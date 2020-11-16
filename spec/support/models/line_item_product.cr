class LineItemProduct < BaseModel
  skip_default_columns

  table :line_items_products do
    primary_key id : UUID
    timestamps
    belongs_to line_item : LineItem
    belongs_to product : Product
  end
end
