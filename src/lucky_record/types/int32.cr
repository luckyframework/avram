class LuckyRecord::Int32Type < LuckyRecord::Type
  alias BaseType = Int32

  def self.cast(value : String)
    SuccessfulCast(Int32).new value.to_i
  rescue ArgumentError
    FailedCast.new
  end

  def self.serialize(value : Int32)
    value.to_s
  end
end
