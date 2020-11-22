class Product < BaseModel
  skip_default_columns

  table do
    primary_key id : UUID
    has_many line_items_products : LineItemProduct
    has_many line_items : LineItem, through: [:line_items_products, :line_item]
    timestamps
  end
end
