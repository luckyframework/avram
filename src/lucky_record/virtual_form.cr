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
    self.class.name.underscore.gsub("_form", "")
  end
end
