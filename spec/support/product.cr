class Product < Avram::Model
  skip_default_columns

  table :products do
    primary_key id : UUID
    has_many line_items_products : LineItemProduct
    has_many line_items : LineItem, through: :line_items_products
    timestamps
  end
end
