class Avram::Events::SaveSuccessEvent < Pulsar::Event
  getter :operation_class, :attributes

  def initialize(
    @operation_class : String,
    @attributes : Array(Avram::GenericAttribute)
  )
  end
end
