class Bucket < BaseModel
  COLUMN_SQL = column_names.join(", ") { |col| "buckets.#{col}" }

  enum Size
    ExtraSmall
    Small
    Medium
    Large
    ExtraLarge
    Tub
  end

  table do
    column bools : Array(Bool) = [] of Bool
    column small_numbers : Array(Int16) = [] of Int16
    column numbers : Array(Int32)?
    column big_numbers : Array(Int64) = [] of Int64
    column names : Array(String) = [] of String
    column floaty_numbers : Array(Float64) = [] of Float64
    column oody_things : Array(UUID) = [] of UUID
    column enums : Array(Bucket::Size) = [] of Bucket::Size, converter: PG::EnumArrayConverter(Bucket::Size)
  end
end
