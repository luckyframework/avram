abstract class BaseBox < Avram::Box
  SEQUENCES = {} of String => Int32

  def self.build
    new.build
  end

  def build
    build_model
  end

  def build_pair
    [build, build]
  end

  def sequence(value : String) : String
    SEQUENCES[value] ||= 0
    SEQUENCES[value] += 1
    "#{value}-#{SEQUENCES[value]}"
  end
end
