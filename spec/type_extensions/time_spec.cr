require "../../spec_helper"

describe "Time column type" do
  describe ".parse" do
    it "casts an ISO8601 String successfully" do
      time = Time.new.to_s("%FT%X%z")

      result = Time::Lucky.parse(time)

      result.should be_a(Avram::Type::SuccessfulCast(Time))
    end

    it "casts a Time successfully" do
      time = Time.new

      result = Time::Lucky.parse(time)

      result.value.should eq(time)
    end

    it "can't cast an invalid value" do
      time = Time.new

      result = Time::Lucky.parse("oh no")

      result.should be_a(Avram::Type::FailedCast)
    end
  end
end
