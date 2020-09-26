struct Time
  extend Avram::Type

  TIME_FORMATS = [
    Time::Format::ISO_8601_DATE_TIME,
    Time::Format::RFC_2822,
    Time::Format::RFC_3339,
    # Dates and times go last, otherwise it will parse strings with both
    # dates *and* times incorrectly.
    Time::Format::HTTP_DATE,
    Time::Format::ISO_8601_DATE,
    Time::Format::ISO_8601_TIME,
  ]

  def self._parse_attribute(value : String) : Avram::Type::SuccessfulCast(Time) | Avram::Type::FailedCast
    # Prefer user defined string formats
    _try_parsing_with_string_formats(value) ||
      # Then try default formats
      _try_parsing_with_default_formatters(value) ||
      # Fail if none of them work
      Avram::Type::FailedCast.new
  end

  def self._try_parsing_with_default_formatters(value : String)
    TIME_FORMATS.find do |format|
      begin
        format.parse(value)
      rescue e : Time::Format::Error
        nil
      end
    end.try do |format|
      Avram::Type::SuccessfulCast.new format.parse(value).to_utc
    end
  end

  def self._try_parsing_with_string_formats(value)
    Avram.settings.time_formats.find do |format|
      begin
        Time.parse(value, format, Time::Location.load("UTC"))
      rescue e : Time::Format::Error
        nil
      end
    end.try do |format|
      Avram::Type::SuccessfulCast.new Time.parse(value, format, Time::Location.load("UTC")).to_utc
    end
  end

  module Lucky
    alias ColumnType = Time

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)
    end
  end
end
