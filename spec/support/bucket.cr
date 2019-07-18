class Bucket < BaseModel
  table do
    column bools : Array(Bool)
    column small_numbers : Array(Int16)
    column numbers : Array(Int32)
    column big_numbers : Array(Int64)
    column names : Array(String)
  end
end
