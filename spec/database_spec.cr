require "./spec_helper"

describe Avram::Database do
  describe "listen" do
    it "yields the payload from a notify" do
      TestDatabase.listen("dinner_time") do |notification|
        notification.channel.should eq "dinner_time"
        notification.payload.should eq "Tacos"
      end

      TestDatabase.exec("SELECT pg_notify('dinner_time', 'Tacos')")
    end
  end
end
