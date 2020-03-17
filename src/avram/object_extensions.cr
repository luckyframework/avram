class Object
  def blank_for_validates_required? : Bool
    blank?
  end
end

class Array(T)
  # Arrays of any size should be considered present
  def blank_for_validates_required? : Bool
    false
  end
end

struct Bool
  def blank_for_validates_required? : Bool
    false
  end
end

struct Char
  def blank_for_validates_required? : Bool
    blank?
  end
end

struct Nil
  def blank_for_validates_required? : Bool
    blank?
  end
end
