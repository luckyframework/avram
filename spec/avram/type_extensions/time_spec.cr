require "../../spec_helper"

enum TimeComponent
  Year
  Month
  Day
  Hour
  Minute
  Second
end

struct FormattedTime
  property label : String
  property value : String
  property components : Array(TimeComponent)

  def initialize(@label : String, @value : String, excluded_components : Array(TimeComponent) = [] of TimeComponent)
    @components = [
      TimeComponent::Year,
      TimeComponent::Month,
      TimeComponent::Day,
      TimeComponent::Hour,
      TimeComponent::Minute,
      TimeComponent::Second,
    ] - excluded_components
  end
end

describe "Time column type" do
  describe ".parse" do
    it "casts various formats successfully" do
      time = Time.utc
      times = [
        FormattedTime.new("ISO 8601", time.to_s("%FT%X%z")),
        FormattedTime.new("RFC 2822", time.to_rfc2822),
        FormattedTime.new("RFC 3339", time.to_rfc3339),
        FormattedTime.new("DateTime HTML Input", time.to_s("%Y-%m-%dT%H:%M:%S")),
        FormattedTime.new("DateTime HTML Input (no seconds)", time.to_s("%Y-%m-%dT%H:%M"), excluded_components: [TimeComponent::Second]),
        FormattedTime.new("HTTP Date", time.to_s("%a, %d %b %Y %H:%M:%S GMT")),
      ]

      times.each do |formatted_time|
        result = Time.adapter.parse(formatted_time.value)
        result.should be_a(Avram::Type::SuccessfulCast(Time))

        unless result.is_a? Avram::Type::SuccessfulCast(Time)
          next
        end

        result.value.year.should eq(time.year) if formatted_time.components.includes? TimeComponent::Year
        result.value.month.should eq(time.month) if formatted_time.components.includes? TimeComponent::Month
        result.value.day.should eq(time.day) if formatted_time.components.includes? TimeComponent::Day
        result.value.hour.should eq(time.hour) if formatted_time.components.includes? TimeComponent::Hour
        result.value.minute.should eq(time.minute) if formatted_time.components.includes? TimeComponent::Minute
        result.value.second.should eq(time.second) if formatted_time.components.includes? TimeComponent::Second
      end
    end

    it "allows adding other formats" do
      Avram.temp_config(time_formats: ["%Y-%B-%-d"]) do
        result = Time.adapter.parse("2017-January-30")

        result.should be_a(Avram::Type::SuccessfulCast(Time))
        value = result.as(Avram::Type::SuccessfulCast(Time)).value
        value.year.should eq(2017)
        value.month.should eq(1)
        value.day.should eq(30)
      end
    end

    it "casts a Time successfully" do
      time = Time.local

      result = Time.adapter.parse(time)

      result.value.should eq(time)
    end

    it "can't cast an invalid value" do
      result = Time.adapter.parse("oh no")

      result.should be_a(Avram::Type::FailedCast)
    end
  end
end
