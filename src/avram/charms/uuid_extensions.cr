struct UUID
  extend Avram::Type

  def self.parse_attribute(value : String)
    Avram::Type::SuccessfulCast(UUID).new(UUID.new(value))
  rescue
    Avram::Type::FailedCast.new
  end

  def self.from_rs(rs)
    rs.read(String?).try { |uuid| UUID.new(uuid) }
  end

  module Lucky
    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
