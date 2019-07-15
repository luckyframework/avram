class Bucket < BaseModel
  table do
    column bools : Array(Bool)
    column prices : Array(Float64)
    column small_numbers : Array(Int16)
    column numbers : Array(Int32)
    column big_numbers : Array(Int64)
    column names : Array(String)
    column dates : Array(Time)
    column ids : Array(UUID)
  end
end
