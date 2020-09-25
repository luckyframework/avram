class Array(T)
  # Proxy to the `T`'s adapter so we can call methods like
  # `Array(String).adapter.to_db(["test"])`
  def self.adapter
    T
  end

  module Float64LuckyConverter
    def self.from_rs(rs)
      rs.read(Array(PG::Numeric)?).try &.map &.to_f
    end
  end
end
