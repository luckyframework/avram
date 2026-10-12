class CustomPriceQuery
  class Result
    include DB::Serializable

    @[DB::Field(converter: PG::NumericFloatConverter)]
    property total : Float64
  end

  def self.total : Float64
    query = <<-SQL
    SELECT SUM(in_cents) / 100.0 AS total
    FROM prices
    SQL

    # Using `query_all` instead of scalar in order to map to
    # the `CustomPriceQuery::Result` object instead of straight to Float64
    result = TestDatabase.query_all(query, as: CustomPriceQuery::Result).first
    result.total
  end
end
