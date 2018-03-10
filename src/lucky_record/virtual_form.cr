require "./allow_virtual"

class LuckyRecord::VirtualForm
  include LuckyRecord::AllowVirtual
  include LuckyRecord::Validations

  @params : LuckyRecord::Paramable
  getter params

  def initialize(@params)
  end

  def initialize
    @params = LuckyRecord::Params.new
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
end
