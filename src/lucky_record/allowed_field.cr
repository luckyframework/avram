require "./field"

class LuckyRecord::AllowedField(T)
  forward_missing_to @field

  def initialize(@field : LuckyRecord::Field(T))
  end
end
