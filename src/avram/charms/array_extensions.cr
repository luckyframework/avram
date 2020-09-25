class Array(T)
  def self.adapter
    self
  end

  def self.to_db(values : Array(T))
    PQ::Param.encode_array(values)
  end

  module Float64LuckyConverter
    def self.from_rs(rs)
      rs.read(Array(PG::Numeric)?).try &.map &.to_f
    end
  end
end
