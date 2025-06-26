module Avram::Expectations
  struct HaveCustomErrorExpectation
    def initialize(@name : Symbol, @message : Regex? = nil)
    end

    def self.new(name, message : String)
      new(name, /#{message}/)
    end

    def match(operation : OperationErrors) : Bool
      return false unless errors = operation.custom_errors[@name]?
      @message.try { |message| return errors.any?(&.=~ message) }
      !errors.empty?
    end

    def failure_message(operation : OperationErrors) : String
      @message.try do |message|
        return "Expected :#{@name} to have the error '#{message.source}'"
      end

      "Expected :#{@name} to have an error"
    end

    def negative_failure_message(operation : OperationErrors) : String
      @message.try do |message|
        return "Expected :#{@name} to not have the error '#{message.source}'"
      end

      <<-MSG
        Expected :#{@name} to not have an error, got errors:
        #{HaveErrorExpectation.list(operation.custom_errors[@name])}
        MSG
    end
  end
end
