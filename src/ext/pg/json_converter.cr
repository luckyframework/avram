# This is used for serialized JSON objects.
# e.g. `column theme : Theme, serialize: true`
module JSONConverter(T)
  def self.from_rs(rs : DB::ResultSet)
    value = rs.read(JSON::PullParser?)
    T.new(value) if value
  end
end
