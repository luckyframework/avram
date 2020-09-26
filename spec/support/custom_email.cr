class CustomEmail
  extend Avram::Type

  def self._parse_attribute(value : String)
    Avram::Type::SuccessfulCast(CustomEmail).new(CustomEmail.new(value))
  end

  def self._to_db(value : String)
    CustomEmail.new(value).to_s
  end

  def initialize(@email : String)
  end

  def to_s
    value
  end

  private def value
    @email.strip.downcase
  end

  def blank?
    @email.blank?
  end

  module Lucky
    alias ColumnType = String

    class Criteria(T, V) < String::Lucky::Criteria(T, V)
      @upper = false
      @lower = false
    end
  end
end
