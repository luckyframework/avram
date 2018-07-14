require "./line_item"
require "./product"

class LineItemProduct < LuckyRecord::Model
  table :line_items_products, primary_key_type: :uuid do
    belongs_to line_item : LineItem
    belongs_to product : Product
  end
end
