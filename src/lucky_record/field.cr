class LuckyRecord::Field(T)
  getter :name
  getter :value
  getter :form_name
  @errors = [] of String
  @changed = false

  def initialize(@name : Symbol, @param : String?, @value : T, @form_name : String)
  end

  @_fillable : LuckyRecord::FillableField(T)?

  def fillable
    @_fillable ||= begin
      LuckyRecord::FillableField.new(name: @name, param: @param, value: @value, form_name: @form_name).tap do |field|
        errors.each do |error|
          field.add_error error
        end
      end
    end
  end

  def param
    @param || value.to_s
  end

  def add_error(message : String = "is invalid")
    @errors << message
  end

  def add_error(message : (Proc | LuckyRecord::CallableErrorMessage))
    message_string = message.call(@name.to_s, @value.to_s)
    add_error(message_string)
  end

  def reset_errors
    @errors = [] of String
  end

  def errors
    @errors.uniq
  end

  def value
    value = @value
    if value.is_a?(String) && value.blank?
      nil
    else
      value
    end
  end

  def valid?
    errors.empty?
  end

  def value=(@value)
    @changed = true
  end

  def changed?
    @changed
  end
end
