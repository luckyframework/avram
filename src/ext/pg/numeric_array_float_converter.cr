# Extends the PG shard and adds a converter for
# converting `Array(PG::Numeric)` columns to `Array(Float64)`. This
# can be used with raw SQL queries.
# ```
# @[DB::Field(converter: PG::NumericArrayFloatConverter)]
# property average_amount : Array(Float64)
# ```
module PG::NumericArrayFloatConverter
  def self.from_rs(rs : DB::ResultSet)
    rs.read(Array(PG::Numeric)).map(&.to_f)
  end
end
