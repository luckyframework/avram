require "./validations"
require "./define_attribute"
require "./operation_mixins/operation_errors"
require "./operation_mixins/param_key_override"
require "./operation_mixins/needy_initializer"

abstract class Avram::Operation
  include Avram::DefineAttribute
  include Avram::Callbacks
  include Avram::NeedyInitializer
  include Avram::Validations
  include Avram::OperationErrors
  include Avram::ParamKeyOverride

  @params : Avram::Paramable
  getter :params

  # Yields the instance of the operation, and the return value from
  # the `run` instance method.
  #
  # ```
  # MyOperation.run do |operation, value|
  #  # operation is complete
  # end
  # ```
  def self.run(*args, **named_args)
    params = Avram::Params.new
    run(params, *args, **named_args) do |operation, value|
      yield operation, value
    end
  end

  def self.run!(*args, **named_args)
    params = Avram::Params.new
    run!(params, *args, **named_args)
  end

  # Yields the instance of the operation, and the return value from
  # the `run` instance method.
  #
  # ```
  # MyOperation.run(params) do |operation, value|
  #  # operation is complete
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

  def self.run!(params : Avram::Paramable, *args, **named_args)
    operation = self.new(params, *args, **named_args)
    operation.before_run
    value = operation.run
    if operation.valid?
      operation.after_run(value)
    else
      value = nil
    end
    raise Avram::FailedOperation.new("The operation failed to return a value") unless value
    operation
  end

  abstract def run

  def initialize
    @params = Avram::Params.new
  end

  def valid?
    attributes.all? &.valid?
  end

  def self.param_key
    name.underscore
  end
end
