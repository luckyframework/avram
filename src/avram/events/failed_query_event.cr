class Avram::Events::FailedQueryEvent < Pulsar::Event
  getter :error_message, :query, :args, :queryable

  def initialize(@error_message : String, @query : String, @args : String?, @queryable : String? = nil)
  end
end
