# Extends the PG shard and adds a converter for
# converting `PG::Numeric` columns to `Float64`. This
# can be used with raw SQL queries.
# ```
# @[DB::Field(converter: PG::NumericFloatConverter)]
# property average_amount : Float64
# ```
module PG::NumericFloatConverter
  def self.from_rs(rs : DB::ResultSet)
    rs.read(PG::Numeric).to_f
  end
end
