require "./virtual"
require "./save_operation_errors"
require "./param_key"

class Avram::VirtualForm
  macro inherited
    {% raise "Avram::VirtualForm has been renamed to Avram::VirtualOperation. Please inherit from Avram::VirtualOperation." %}
  end
end

class Avram::VirtualOperation
  include Avram::Virtual
  include Avram::Validations
  include Avram::SaveOperationErrors
  include Avram::ParamKey

  @params : Avram::Paramable
  getter params

  def initialize(@params)
  end

  def initialize
    @params = Avram::Params.new
  end

  def valid?
    virtual_attributes.all? &.valid?
  end

  def attributes
    virtual_attributes
  end
end
