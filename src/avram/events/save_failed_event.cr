class Avram::Events::SaveFailedEvent < Pulsar::Event
  getter :operation_class, :attributes

  def initialize(
    @operation_class : String,
    @attributes : Array(Avram::GenericAttribute)
  )
  end

  def invalid_attributes
    attributes.reject(&.valid?)
  end

  def error_messages_as_string
    invalid_attributes.map do |attribute|
      "#{attribute.name} #{attribute.errors.join(", ")}"
    end.join(". ")
  end
end
