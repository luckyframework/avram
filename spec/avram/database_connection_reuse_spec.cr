require "../spec_helper"

# Returns whether another fiber can check out `conn` while the caller holds it.
private def other_fiber_gets?(conn : DB::Connection) : Bool
  result = Channel(Bool).new(1)
  spawn do
    got = begin
      SingleConnectionDatabase.run(&.same?(conn))
    rescue DB::PoolTimeout
      false
    end
    result.send(got)
  end
  result.receive
end

# The connection went back to the pool exactly once.
private def released_once!(conn : DB::Connection) : Nil
  conn.closed?.should be_false
  other_fiber_gets?(conn).should be_true
end

describe "Avram::Database connection reuse within a fiber" do
  it "a nested query does not release the outer block's connection" do
    outer = SingleConnectionDatabase.run do |db|
      SingleConnectionDatabase.query_one("SELECT 1", as: Int32).should eq(1)

      other_fiber_gets?(db).should be_false
      db.scalar("SELECT 2").should eq(2)
      db
    end

    released_once!(outer)
  end

  it "a nested transaction does not release the outer block's connection" do
    outer = SingleConnectionDatabase.run do |db|
      SingleConnectionDatabase.transaction do
        SingleConnectionDatabase.query_one("SELECT 1", as: Int32)
      end

      other_fiber_gets?(db).should be_false
      db
    end

    released_once!(outer)
  end

  it "keeps an advisory lock and its unlock on the same, unshared connection" do
    outer = SingleConnectionDatabase.run do |db|
      db.scalar("SELECT pg_try_advisory_lock(42)").should be_true
      begin
        SingleConnectionDatabase.query_all("SELECT generate_series(1, 3)", as: Int32).size.should eq(3)
        other_fiber_gets?(db).should be_false
      ensure
        db.scalar("SELECT pg_advisory_unlock(42)").should be_true
      end
      db
    end

    released_once!(outer)
  end

  it "a nested error rescued by the outer block does not release the connection" do
    outer = SingleConnectionDatabase.run do |db|
      begin
        SingleConnectionDatabase.run { raise "boom" }
      rescue
      end

      other_fiber_gets?(db).should be_false
      db
    end

    released_once!(outer)
  end

  it "releases the connection when a top-level block raises" do
    conn : DB::Connection? = nil
    expect_raises(Exception, "boom") do
      SingleConnectionDatabase.run do |db|
        conn = db
        raise "boom"
      end
    end

    conn.should be_a(DB::Connection)
    released_once!(conn.as(DB::Connection))
  end
end
