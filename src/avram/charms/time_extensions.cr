struct Time
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Time
    include Avram::Type

    TIME_FORMATS = [
      Time::Format::ISO_8601_DATE_TIME,
      Time::Format::RFC_2822,
      Time::Format::RFC_3339,
      # HTML datetime-local inputs are basically RFC 3339 without the timezone:
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/datetime-local
      Time::Format.new("%Y-%m-%dT%H:%M:%S", Time::Location::UTC),
      Time::Format.new("%Y-%m-%dT%H:%M", Time::Location::UTC),
      # Dates and times go last, otherwise it will parse strings with both
      # dates *and* times incorrectly.
      Time::Format::HTTP_DATE,
      Time::Format::ISO_8601_DATE,
      Time::Format::ISO_8601_TIME,
    ]

    def self.criteria(query : T, column) forall T
      Criteria(T, Time).new(query, column)
    end

    def from_db!(value : Time)
      value
    end

    def parse(value : String) : SuccessfulCast(Time) | FailedCast
      # Prefer user defined string formats
      try_parsing_with_string_formats(value) ||
        # Then try default formats
        try_parsing_with_default_formatters(value) ||
        # Fail if none of them work
        FailedCast.new
    end

    def self.try_parsing_with_default_formatters(value : String)
      TIME_FORMATS.find do |format|
        begin
          format.parse(value)
        rescue e : Time::Format::Error
          nil
        end
      end.try do |format|
        SuccessfulCast.new format.parse(value).to_utc
      end
    end

    def self.try_parsing_with_string_formats(value)
      Avram.settings.time_formats.find do |format|
        begin
          Time.parse(value, format, Time::Location.load("UTC"))
        rescue e : Time::Format::Error
          nil
        end
      end.try do |format|
        SuccessfulCast.new Time.parse(value, format, Time::Location.load("UTC")).to_utc
      end
    end

    def parse(value : Time)
      SuccessfulCast(Time).new value
    end

    def parse(values : Array(Time))
      SuccessfulCast(Array(Time)).new values
    end

    def to_db(value : Time) : String
      value.to_s("%F %X.%6N %z")
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)
      include Avram::ExtractCriteria

      define_function_criteria(as_date, String, "DATE")
    end
  end
end
