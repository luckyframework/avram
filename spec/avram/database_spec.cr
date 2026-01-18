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

  describe "vacuum", tags: Avram::SpecHelper::TRUNCATE do
    it "runs a VACUUM" do
      TestDatabase.vacuum

      query_event = Avram::Events::QueryEvent.logged_events.first
      query_event.query.should eq("VACUUM")
    end

    it "runs a VACUUM on a specific table" do
      TestDatabase.vacuum(Bucket)

      query_event = Avram::Events::QueryEvent.logged_events.first
      query_event.query.should eq("VACUUM buckets")
    end
  end
end
