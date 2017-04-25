class LuckyRecord::Field(T)
  property :name, :value, :errors

  def initialize(@name : Symbol, @value : T, @errors : Array(String))
  end
end
