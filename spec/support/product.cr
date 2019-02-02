class Product < Avram::Model
  table :products, primary_key_type: :uuid do
    has_many line_items_products : LineItemProduct
    has_many line_items : LineItem, through: :line_items_products
  end
end
