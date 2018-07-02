class Scan < LuckyRecord::Model
  table :scans do
    column scanned_at : Time
    belongs_to line_item : LineItem
  end
end
