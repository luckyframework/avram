class Array(T)
  # Proxy to the `T`'s adapter so we can call methods like
  # `Array(String).adapter._to_db(["test"])`
  def self._to_db(values : Array(T))
    PQ::Param.encode_array(values)
  end
end
