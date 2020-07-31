class Avram::Events::QueryEvent < Pulsar::TimedEvent
  getter :query, :args, :queryable

  def initialize(@query : String, @args : String?, @queryable : String? = nil)
  end
end
