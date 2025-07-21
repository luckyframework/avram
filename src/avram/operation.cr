require "../lucky/base_operation"
require "./operation_adapters"

# Now Avram::Operation inherits from Lucky::BaseOperation
# but maintains backward compatibility through adapter modules
abstract class Avram::Operation < Lucky::BaseOperation
  include Avram::NeedyInitializer
  include Avram::DefineAttribute
  include Avram::Validations
  include Avram::OperationErrors
  include Avram::ParamKeyOverride
  include Avram::Callbacks

  def self.run(*args, **named_args, &)
    params = Avram::Params.new
    run(params, *args, **named_args) do |operation, value|
      yield operation, value
    end
  end

  def self.run!(*args, **named_args)
    params = Avram::Params.new
    run!(params, *args, **named_args)
  end

  def self.run(params : Avram::Paramable, *args, **named_args, &)
    operation = self.new(params, *args, **named_args)
    value = nil

    operation.before_run

    if operation.valid?
      value = operation.run
      operation.after_run(value)
    end

    yield operation, value
  end

  def self.run!(params : Avram::Paramable, *args, **named_args)
    run(params, *args, **named_args) do |_operation, value|
      raise Avram::FailedOperation.new("The operation failed to return a value") unless value
      value
    end
  end

  # Cast params to Avram::Paramable
  def params : Avram::Paramable
    @params.as(Avram::Paramable)
  end

  def initialize(@params : Avram::Paramable)
  end

  def initialize
    @params = Avram::Params.new
  end

  # :nodoc:
  def default_validations; end

  # Returns `true` if all attributes are valid,
  # and there's no custom errors
  def valid? : Bool
    default_validations
    custom_errors.empty? && attributes.all?(&.valid?)
  end
end
