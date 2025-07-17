# Extends the PG shard and adds a converter for
# converting `Array(Int)` columns to `Array(Enum)`. This
# can be used with raw SQL queries.
# ```
# enum Colors
#   Red
# end
# @[DB::Field(converter: PG::EnumArrayConverter(Colors))]
# property colors : Array(Colors)
# ```
module PG::EnumArrayConverter(T)
  def self.from_rs(result_set : DB::ResultSet)
    result_set.read(Array(typeof(T.values.first.value))).map { |value| T.from_value(value) }
  end
end
