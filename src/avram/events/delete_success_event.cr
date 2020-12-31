class Avram::Events::DeleteSuccessEvent < Pulsar::Event
  getter :operation_class

  def initialize(@operation_class : String)
  end
end
