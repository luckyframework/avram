class Bucket < BaseModel
  COLUMN_SQL = "buckets.id, buckets.created_at, buckets.updated_at, buckets.bools, buckets.small_numbers, buckets.numbers, buckets.big_numbers, buckets.names, buckets.floaty_numbers, buckets.oody_things"
  table do
    column bools : Array(Bool)
    column small_numbers : Array(Int16)
    column numbers : Array(Int32)?
    column big_numbers : Array(Int64)
    column names : Array(String)
    column floaty_numbers : Array(Float64)
    column oody_things : Array(UUID)
  end
end
