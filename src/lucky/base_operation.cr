require "./paramable"
require "./basic_params"
require "./failed_operation_error"

# Base operation class that provides the fundamental operation pattern
# without any specific attribute or validation implementation
abstract class Lucky::BaseOperation
  getter params : Lucky::Paramable

  # Yields the instance of the operation, and the return value from
  # the `run` instance method.
  #
  # ```
  # MyOperation.run do |operation, value|
  #   # operation is complete
  # end
  # ```
  def self.run(*args, **named_args, &)
    params = Lucky::BasicParams.new
    run(params, *args, **named_args) do |operation, value|
      yield operation, value
    end
  end

  # Returns the value from the `run` instance method.
  # or raise `Lucky::FailedOperationError` if the operation fails.
  #
  # ```
  # value = MyOperation.run!
  # ```
  def self.run!(*args, **named_args)
    params = Lucky::BasicParams.new
    run!(params, *args, **named_args)
  end

  # Yields the instance of the operation, and the return value from
  # the `run` instance method.
  #
  # ```
  # MyOperation.run(params) do |operation, value|
  #   # operation is complete
  # end
  # ```
  def self.run(params : Lucky::Paramable, *args, **named_args, &)
    operation = self.new(params, *args, **named_args)
    value = nil

    operation.before_run

    if operation.valid?
      value = operation.run
      operation.after_run(value)
    end

    yield operation, value
  end

  # Returns the value from the `run` instance method.
  # or raise `Lucky::FailedOperationError` if the operation fails.
  #
  # ```
  # value = MyOperation.run!(params)
  # ```
  def self.run!(params : Lucky::Paramable, *args, **named_args)
    run(params, *args, **named_args) do |_operation, value|
      raise Lucky::FailedOperationError.new("The operation failed to return a value") unless value
      value
    end
  end

  # Hook called before run
  def before_run
  end

  # The main operation logic to be implemented by subclasses
  abstract def run

  # Hook called after run
  def after_run(_value)
  end

  def initialize(@params)
  end

  def initialize
    @params = Lucky::BasicParams.new
  end

  # Abstract methods that subclasses must implement
  abstract def valid? : Bool
  abstract def attributes
  abstract def custom_errors

  def self.param_key : String
    name.underscore
  end
end
