class LuckyRecord::Field(T)
  getter :name
  getter :param
  getter :value
  @errors = [] of String
  @changed = false

  def initialize(@name : Symbol, @param : String?, @value : T)
  end

  def add_error(message : String)
    @errors << message
  end

  def errors
    @errors.uniq
  end

  def valid?
    errors.empty?
  end

  def value=(@value)
    @changed = true
  end

  def changed?
    @changed
  end
end
