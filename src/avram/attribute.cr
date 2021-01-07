class Avram::Attribute(T)
  alias ErrorMessage = String | Proc(String, String, String) | Avram::CallableErrorMessage
  getter name : Symbol
  setter value : T?
  getter param_key : String
  @errors = [] of String
  @param : Avram::Uploadable | String | Nil

  def initialize(@name, @value : T?, @param_key, @param = nil)
    @original_value = @value
  end

  @_permitted : Avram::PermittedAttribute(T)?

  def permitted
    @_permitted ||= begin
      Avram::PermittedAttribute(T).new(name: @name, param: @param, value: @value, param_key: @param_key).tap do |attribute|
        errors.each do |error|
          attribute.add_error error
        end
      end
    end
  end

  def param : Avram::Uploadable | String
    @param || value.to_s
  end

  def add_error(message : String = "is invalid")
    @errors << message
  end

  def add_error(message : (Proc | Avram::CallableErrorMessage))
    message_string = message.call(@name.to_s, @value.to_s)
    add_error(message_string)
  end

  def reset_errors
    @errors = [] of String
  end

  def errors : Array(String)
    @errors.uniq
  end

  def value : T?
    ensure_no_blank(@value)
  end

  def original_value : T?
    ensure_no_blank(@original_value)
  end

  private def ensure_no_blank(value : T?) : T?
    if value.is_a?(Avram::Uploadable | String) && value.blank?
      nil
    else
      value
    end
  end

  def valid? : Bool
    errors.empty?
  end

  def changed?(from : T? | Nothing = Nothing.new, to : T? | Nothing = Nothing.new) : Bool
    from = from.is_a?(Nothing) ? true : from == original_value
    to = to.is_a?(Nothing) ? true : to == value
    value != original_value && from && to
  end

  def extract(params : Avram::Paramable)
    extract(params, type: T)
  end

  private def extract(params, type : Avram::Uploadable.class)
    file = params.nested_file?(param_key)
    @param = param_val = file.try(&.[]?(name.to_s))
    return if param_val.nil?

    parse_result = Avram::Uploadable.adapter.parse(param_val)
    if parse_result.is_a? Avram::Type::SuccessfulCast
      self.value = parse_result.value
    else
      add_error("is invalid")
    end
  end

  private def extract(params, type)
    nested_params = params.nested(param_key)
    @param = param_val = nested_params[name.to_s]?
    return if param_val.nil?

    parse_result = type.adapter.parse(param_val)
    if parse_result.is_a? Avram::Type::SuccessfulCast
      self.value = parse_result.value
    else
      add_error("is invalid")
    end
  end

  class Nothing
  end
end
