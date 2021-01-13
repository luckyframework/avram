require "../spec_helper"

describe "Time column type" do
  describe ".parse" do
    it "casts various formats successfully" do
      time = Time.utc
      times = {
        iso8601:             time.to_s("%FT%X%z"),
        rfc2822:             time.to_rfc2822,
        rfc3339:             time.to_rfc3339,
        datetime_html_input: time.to_s("%Y-%m-%dT%H:%M:%S"),
        http_date:           time.to_s("%a, %d %b %Y %H:%M:%S GMT"),
      }
      times.each do |_format, item|
        result = Time.adapter.parse(item)
        result.should be_a(Avram::Type::SuccessfulCast(Time))

        unless result.is_a? Avram::Type::SuccessfulCast(Time)
          next
        end

        result.value.year.should eq(time.year)
        result.value.month.should eq(time.month)
        result.value.day.should eq(time.day)
        result.value.hour.should eq(time.hour)
        result.value.minute.should eq(time.minute)
        result.value.second.should eq(time.second)
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
