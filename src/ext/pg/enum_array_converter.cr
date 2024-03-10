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
  def self.from_rs(rs : DB::ResultSet)
    rs.read(Array(typeof(T.values.first.value))).map { |i| T.from_value(i) }
  end
end
