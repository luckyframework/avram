class Avram::Events::DeleteFailedEvent < Pulsar::Event
  getter :operation_class, :errors

  def initialize(
    @operation_class : String,
    @errors : Hash(Symbol, Array(String))
  )
  end

  def error_messages_as_string
    String.build do |msg|
      errors.each do |key, messages|
        msg << "#{key} #{messages.join(", ")}"
      end
    end
  end
end
