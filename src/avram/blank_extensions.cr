struct Bool
  def blank? : Bool
    false
  end
end

struct Time
  def blank? : Bool
    nil?
  end
end

struct Int16
  def blank? : Bool
    nil?
  end
end

struct Int32
  def blank? : Bool
    nil?
  end
end

struct Int64
  def blank? : Bool
    nil?
  end
end

struct Float64
  def blank? : Bool
    nil?
  end
end

struct Nil
  def blank? : Bool
    nil?
  end
end

struct JSON::Any
  def blank? : Bool
    nil?
  end
end

struct UUID
  def blank? : Bool
    false
  end
end

class Array(T)
  def blank? : Bool
    empty?
  end
end

struct Slice(T)
  def blank? : Bool
    empty?
  end
end
