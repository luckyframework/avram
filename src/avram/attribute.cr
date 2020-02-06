class Avram::Attribute(T)
  alias ErrorMessage = String | Proc(String, String, String) | Avram::CallableErrorMessage
  getter :name
  getter :param_key
  @errors = [] of String
  @explicit_nil = false

  def initialize(@name : Symbol, @param : String?, @value : T, @param_key : String)
    @original_value = @value
  end

  @_permitted : Avram::PermittedAttribute(T)?

  def permitted
    @_permitted ||= begin
      Avram::PermittedAttribute.new(name: @name, param: @param, value: @value, param_key: @param_key).tap do |attribute|
        errors.each do |error|
          attribute.add_error error
        end
      end
    end
  end

  def param
    @param || value.to_s
  end

  def add_error(message : ErrorMessage = "is invalid")
    perform_add_error(message)
  end

  private def perform_add_error(message : String = "is invalid")
    @errors << message
  end

  private def perform_add_error(message : (Proc | Avram::CallableErrorMessage))
    message_string = message.call(@name.to_s, @value.to_s)
    perform_add_error(message_string)
  end

  def reset_errors
    @errors = [] of String
  end

  def errors
    @errors.uniq
  end

  def value
    ensure_no_blank(@value)
  end

  def value=(@value)
    @explicit_nil = true if @value.nil?
  end

  def original_value
    ensure_no_blank(@original_value)
  end

  private def ensure_no_blank(value : T)
    if value.is_a?(String) && value.blank?
      nil
    else
      value
    end
  end

  def valid?
    errors.empty?
  end

  def changed?(**arguments)
    from = arguments[:from]? ? arguments[:from]? == @original_value : true
    to = arguments[:to]? ? arguments[:to]? == @value : true
    (@value != @original_value || @explicit_nil) && to && from
  end

  def changes
    changed? ? [@original_value, @value] : [] of String | Nil
  end
end
