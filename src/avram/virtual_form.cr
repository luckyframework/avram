require "./virtual"
require "./form_errors"

class Avram::VirtualForm
  include Avram::Virtual
  include Avram::Validations
  include Avram::FormErrors

  @params : Avram::Paramable
  getter params

  def initialize(@params)
  end

  def initialize
    @params = Avram::Params.new
  end

  def form_name
    self.class.form_name
  end

  def self.form_name
    self.name.underscore.gsub("_form", "")
  end

  def valid?
    virtual_fields.all? &.valid?
  end

  def fields
    virtual_fields
  end
end
