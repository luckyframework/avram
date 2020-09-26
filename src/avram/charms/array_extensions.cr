class Array(T)
  # Proxy to the `T`'s adapter so we can call methods like
  # `Array(String).adapter._to_db(["test"])`
  def self.adapter
    T
  end
end
