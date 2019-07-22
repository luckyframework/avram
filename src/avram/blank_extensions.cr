struct Bool
  def blank?
    false
  end
end

struct Time
  def blank?
    nil?
  end
end

struct Int16
  def blank?
    nil?
  end
end

struct Int32
  def blank?
    nil?
  end
end

struct Int64
  def blank?
    nil?
  end
end

struct Float64
  def blank?
    nil?
  end
end

struct Nil
  def blank?
    nil?
  end
end

struct JSON::Any
  def blank?
    nil?
  end
end

struct UUID
  def blank?
    false
  end
end

class Array(T)
  def blank?
    empty?
  end
end
