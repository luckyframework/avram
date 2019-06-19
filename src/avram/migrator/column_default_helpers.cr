module Avram::Migrator::ColumnDefaultHelpers
  alias ColumnDefaultType = String | Time | Int32 | Int64 | Float32 | Float64 | Bool | Symbol | UUID | JSON::Any

  def value_to_string(type : String.class | Time.class | UUID.class, value : String | Time | UUID)
    "'#{value}'"
  end

  def value_to_string(type : Int32.class | Int64.class | Float.class | Bool.class, value : Int32 | Int64 | Float | Bool)
    "#{value}"
  end

  def value_to_string(type : Time.class, value : Symbol)
    if value == :now
      "NOW()"
    else
      raise "Unrecognized value :#{value} for a timestamptz. Please use :now for current timestamp."
    end
  end

  def default_value(type : String.class, default : String)
    " DEFAULT #{value_to_string(type, default)}"
  end

  def default_value(type : Int64.class, default : Int32 | Int64)
    " DEFAULT #{value_to_string(type, default)}"
  end

  def default_value(type : Int32.class, default : Int32)
    " DEFAULT #{value_to_string(type, default)}"
  end

  def default_value(type : Bool.class, default : Bool)
    " DEFAULT #{value_to_string(type, default)}"
  end

  def default_value(type : Float.class, default : Float)
    " DEFAULT #{value_to_string(type, default)}"
  end

  def default_value(type : Time.class, default : Time)
    " DEFAULT #{value_to_string(type, default.to_utc)}"
  end

  def default_value(type : Time.class, default : Symbol)
    " DEFAULT #{value_to_string(type, default)}"
  end

  def default_value(type : UUID.class, default : UUID)
    " DEFAULT #{value_to_string(type, default)}"
  end

  def default_value(type : JSON::Any.class, default)
    " DEFAULT '#{default.to_json.gsub(/'/, "''")}'"
  end
end
