require "./validations"
require "./save_operation_errors"
require "./define_attribute"
require "./save_operation_errors"
require "./param_key_override"

class Avram::VirtualForm
  macro inherited
    {% raise "Avram::VirtualForm has been renamed to Avram::Operation. Please inherit from Avram::Operation." %}
  end
end

class Avram::Operation
  include Avram::DefineAttribute
  include Avram::Validations
  include Avram::SaveOperationErrors
  include Avram::ParamKeyOverride

  @params : Avram::Paramable
  getter params

  def initialize(@params)
  end

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
