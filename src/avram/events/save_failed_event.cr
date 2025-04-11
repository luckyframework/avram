require "../generic_attribute"

class Avram::Events::SaveFailedEvent < Pulsar::Event
  getter operation_class : String
  getter attributes : Array(Avram::GenericAttribute)

  def initialize(
    @operation_class : String,
    @attributes : Array(Avram::GenericAttribute),
  )
  end

  def invalid_attributes : Array(Avram::GenericAttribute)
    attributes.reject(&.valid?)
  end

  def error_messages_as_string : String
    invalid_attributes.join(". ") do |attribute|
      "#{attribute.name} #{attribute.errors.join(", ")}"
    end
  end
end
