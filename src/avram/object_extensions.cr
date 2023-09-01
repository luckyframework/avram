class Object
  def blank? : Bool
    if self.responds_to?(:empty?)
      self.empty?
    else
      false
    end
  end

  def present? : Bool
    !blank?
  end

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
  def blank? : Bool
    case ord
    when 9, 0xa, 0xb, 0xc, 0xd, 0x20, 0x85, 0xa0, 0x1680, 0x180e,
         0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006,
         0x2007, 0x2008, 0x2009, 0x200a, 0x2028, 0x2029, 0x202f,
         0x205f, 0x3000
      true
    else
      false
    end
  end

  def blank_for_validates_required? : Bool
    blank?
  end
end

struct Nil
  def blank? : Bool
    true
  end

  def blank_for_validates_required? : Bool
    blank?
  end
end
