require "../spec_helper"

describe "Instrumentation" do
  it "publishes the query and args" do
    # using block form to make sure the ResultSet is closed
    TestDatabase.query "SELECT * FROM users" { }

    event = Avram::Events::QueryEvent.logged_events.last
    event.query.should eq("SELECT * FROM users")
    event.queryable.should be_nil
  end

  it "labels the query if coming from a Queryable" do
    UserQuery.new.name("Bob").first?

    event = Avram::Events::QueryEvent.logged_events.last
    event.query.should contain("WHERE users.name = $1")
    event.args.to_s.should contain("Bob")
    event.queryable.should eq("User")
  end

  it "labels the scalar if coming from a Queryable" do
    UserQuery.new.name("Bob").select_count

    event = Avram::Events::QueryEvent.logged_events.last
    event.query.should contain("WHERE users.name = $1")
    event.args.to_s.should contain("Bob")
    event.queryable.should eq("User")
  end

  it "publishes failed queries" do
    expect_raises PQ::PQError do
      TestDatabase.scalar "NOT VALID SORRY"
    end

    event = Avram::Events::FailedQueryEvent.logged_events.last
    event.query.should contain("NOT VALID SORRY")
  end

  it "publishes failed operations" do
    Task::SaveOperation.create do |_op, _task|
      event = Avram::Events::SaveFailedEvent.logged_events.last
      event.operation_class.should eq("Task::SaveOperation")
    end
  end

  it "publishes successful operations" do
    Employee::SaveOperation.create!(name: "Someone Special")

    event = Avram::Events::SaveSuccessEvent.logged_events.last
    event.operation_class.should eq("Employee::SaveOperation")
  end
end
