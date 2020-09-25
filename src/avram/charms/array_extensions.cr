class Array(T)
  # Proxy to the `T`'s adapter so we can call methods like
  # `Array(String).adapter.to_db(["test"])`
  def self.adapter
    T::Lucky
  end
  module Lucky
    module Float64
      def self.from_rs(rs : PG::ResultSet)
        rs.read(Array(PG::Numeric)?).try &.map &.to_f
      end
    end
  end
end
