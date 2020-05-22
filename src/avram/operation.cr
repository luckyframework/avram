require "./validations"
require "./define_attribute"
require "./save_operation_errors"
require "./param_key_override"

abstract class Avram::Operation
  include Avram::DefineAttribute
  include Avram::Callbacks
  include Avram::NeedyInitializer
  include Avram::Validations
  include Avram::SaveOperationErrors
  include Avram::ParamKeyOverride

  @params : Avram::Paramable
  getter params

  def self.run(*args, **named_args)
    params = Avram::Params.new
    run(params, *args, **named_args) do |operation, value|
      yield operation, value
    end
  end

  def self.run(params : Avram::Paramable, *args, **named_args)
    operation = self.new(params, *args, **named_args)
    operation.before_run
    value = operation.run
    operation.after_run(value)
    yield operation, value
  end

  abstract def run

  def initialize(@params : Avram::Paramable)
  end

  def valid?
    attributes.all? &.valid?
  end

  def self.param_key
    name.underscore
  end
end
