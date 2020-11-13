require "./validations"
require "./callbacks"
require "./define_attribute"
require "./operation_errors"
require "./param_key_override"
require "./needy_initializer"

abstract class Avram::Operation
  include Avram::NeedyInitializer
  include Avram::DefineAttribute
  include Avram::Validations
  include Avram::OperationErrors
  include Avram::ParamKeyOverride
  include Avram::Callbacks

  @params : Avram::Paramable
  getter params
  property valid : Bool = true

  # Yields the instance of the operation, and the return value from
  # the `run` instance method.
  #
  # ```
  # MyOperation.run do |operation, value|
  #   # operation is complete
  # end
  # ```
  def self.run(*args, **named_args)
    params = Avram::Params.new
    run(params, *args, **named_args) do |operation, value|
      yield operation, value
    end
  end

  # Returns the value from the `run` instance method.
  # or raise `Avram::FailedOperation` if the operation fails.
  #
  # ```
  # value = MyOperation.run!
  # ```
  def self.run!(*args, **named_args)
    params = Avram::Params.new
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
  def self.run(params : Avram::Paramable, *args, **named_args)
    operation = self.new(params, *args, **named_args)
    operation.before_run
    value = operation.run
    if operation.valid?
      operation.after_run(value)
    else
      value = nil
    end
    yield operation, value
  end

  # Returns the value from the `run` instance method.
  # or raise `Avram::FailedOperation` if the operation fails.
  #
  # ```
  # value = MyOperation.run!(params)
  # ```
  def self.run!(params : Avram::Paramable, *args, **named_args)
    run(params, *args, **named_args) do |_operation, value|
      raise Avram::FailedOperation.new("The operation failed to return a value") unless value
      value
    end
  end

  def before_run
  end

  abstract def run

  def after_run(_value)
  end

  def initialize(@params)
  end

  def initialize
    @params = Avram::Params.new
  end

  # Returns `true` if all attributes are valid.
  # Set `valid` to false to force invalid state.
  def valid?
    return false unless valid
    attributes.all? &.valid?
  end

  def self.param_key
    name.underscore
  end
end
