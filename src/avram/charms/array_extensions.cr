class Array(T)
  # Proxy to the `T`'s adapter so we can call methods like
  # `Array(String).adapter.to_db(["test"])`
  def self.adapter
    T::Lucky
  end
  module Lucky
    module Bool
      def self.from_rs(rs : PG::ResultSet)
        rs.read(Array(::Bool)?)
      end
    end

    module Float64
      def self.from_rs(rs : PG::ResultSet)
        rs.read(Array(PG::Numeric)?).try &.map &.to_f
      end
    end

    module Int16
      def self.from_rs(rs : PG::ResultSet)
        rs.read(Array(::Int16)?)
      end
    end

    module Int32
      def self.from_rs(rs : PG::ResultSet)
        rs.read(Array(::Int32)?)
      end
    end

    module Int64
      def self.from_rs(rs : PG::ResultSet)
        rs.read(Array(::Int64)?)
      end
    end

    module String
      def self.from_rs(rs : PG::ResultSet)
        rs.read(Array(::String)?)
      end
    end
  end
end
