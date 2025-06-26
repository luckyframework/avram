module Avram::Expectations
  struct HaveErrorExpectation
    def initialize(@message : Regex? = nil)
    end

    def self.new(message : String)
      new(/#{message}/)
    end

    def match(attribute : Attribute) : Bool
      @message.try do |message|
        return attribute.errors.any?(&.=~ message)
      end

      !attribute.errors.empty?
    end

    def match(operation : OperationErrors) : Bool
      @message.try do |message|
        return operation.errors.flat_map { |_, errors| errors }.any? do |error|
          error =~ message
        end
      end

      !operation.errors.empty?
    end

    def failure_message(attribute : Attribute) : String
      @message.try do |message|
        return "Expected :#{attribute.name} to have the error '#{message.source}'"
      end

      "Expected :#{attribute.name} to have an error"
    end

    def failure_message(operation : OperationErrors) : String
      @message.try do |message|
        return "Expected operation to have the error '#{message.source}'"
      end

      "Expected operation to have an error"
    end

    def negative_failure_message(attribute : Attribute) : String
      @message.try do |message|
        return "Expected :#{attribute.name} to not have the error '#{message.source}'"
      end

      <<-MSG
      Expected :#{attribute.name} to not have an error, got errors:
      #{self.class.list(attribute.errors)}
      MSG
    end

    def negative_failure_message(operation : OperationErrors) : String
      @message.try do |message|
        return "Expected operation to not have the error '#{message.source}'"
      end

      <<-MSG
        Expected operation to not have an error, got errors:
        #{self.class.list(operation.errors)}
        MSG
    end

    protected def self.list(errors : Hash)
      errors.join do |name, _errors|
        list _errors.map { |error| "#{name}: #{error}" }
      end
    end

    protected def self.list(errors : Array)
      errors.join do |error|
        <<-ERROR
          - #{error}

        ERROR
      end
    end
  end
end
