class Avram::Attribute(T)
  alias ErrorMessage = String | Proc(String, String, String) | Avram::CallableErrorMessage
  getter name : Symbol
  setter value : T?
  getter param_key : String
  @errors = [] of String
  @param : Avram::Uploadable | Array(String) | String | Nil

  # This can be used as an escape hatch when you
  # may have a blank string that's allowed to be saved.
  property? allow_blank : Bool = false

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

  def param : Avram::Uploadable | Array(String) | String
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
    if allow_blank?
      @value
    else
      ensure_no_blank(@value)
    end
  end

  def original_value : T?
    if allow_blank?
      @original_value
    else
      ensure_no_blank(@original_value)
    end
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

  private def extract(params, type : Array(T).class) forall T
    nested_params = params.nested_arrays(param_key)
    param_val = nested_params[name.to_s]?
    @param = param_val.try(&.first?)
    return if param_val.nil?

    parse_result = T.adapter.parse(param_val)
    if parse_result.is_a? Avram::Type::SuccessfulCast
      self.value = parse_result.value
    else
      add_error("is invalid")
    end
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

  # These methods may accidentally get called on attributes
  # inside of operations. Since these methods don't exist,
  # chances are, you meant to call them on the value.
  # ```
  # username.to_s
  # # VS
  # username.value.to_s
  # ```
  def to_s
    call_value_instead_error_message(".to_s")
  end

  # NOTE: to_s(io : IO) is used when passing an object
  # in to string interpolation. Don't override that method.
  def to_s(time_format : String)
    call_value_instead_error_message(".to_s(...)")
  end

  def to_i
    call_value_instead_error_message(".to_i")
  end

  def to_i32
    call_value_instead_error_message(".to_i32")
  end

  def to_i64
    call_value_instead_error_message(".to_i64")
  end

  def to_f
    call_value_instead_error_message(".to_f")
  end

  def to_f64
    call_value_instead_error_message(".to_f64")
  end

  def [](key)
    call_value_instead_error_message(".[key]")
  end

  def []?(key)
    call_value_instead_error_message(".[key]?")
  end

  macro call_value_instead_error_message(method)
    {% raise <<-ERROR

      The #{method.id} method should not be called directly on attributes (#{@type}).
      Did you mean to call it on the value property?

      Try this...

        ▸ attribute.value#{method.id}

      ERROR
    %}
  end
end
