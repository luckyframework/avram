class Scan < BaseModel
  skip_default_columns

  table do
    primary_key id : Int32
    timestamps
    column scanned_at : Time
    belongs_to line_item : LineItem
  end
end
