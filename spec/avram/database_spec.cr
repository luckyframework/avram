require "../spec_helper"

describe Avram::Database do
  describe "listen", tags: Avram::SpecHelper::TRUNCATE do
    it "yields the payload from a notify" do
      done = Channel(Nil).new
      TestDatabase.listen("dinner_time") do |notification|
        notification.channel.should eq "dinner_time"
        notification.payload.should eq "Tacos"
        done.send(nil)
      end

      TestDatabase.exec("SELECT pg_notify('dinner_time', 'Tacos')")
      done.receive
    end
  end
end
