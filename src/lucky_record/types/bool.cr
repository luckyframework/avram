class LuckyRecord::BoolType < LuckyRecord::Type
  alias BaseType = Bool

  def self.cast(value : String)
    if %w(true 1).includes? value
      SuccessfulCast(Bool).new true
    elsif %w(false 0).includes? value
      SuccessfulCast(Bool).new false
    else
      FailedCast.new
    end
  end

  def self.cast(value : Bool)
    SuccessfulCast(Bool).new value
  end

  def self.serialize(value : Bool)
    value.to_s
  end
end
