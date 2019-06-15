require "./virtual"
require "./save_operation_errors"
require "./param_key_override"
require "./form_name"

class Avram::VirtualOperation
  include Avram::Virtual
  include Avram::Validations
  include Avram::SaveOperationErrors
  include Avram::ParamKeyOverride
  include Avram::FormName

  @params : Avram::Paramable
  getter params

  def initialize(@params)
  end

  def initialize
    @params = Avram::Params.new
  end

  def valid?
    virtual_fields.all? &.valid?
  end

  def fields
    virtual_fields
  end
end
