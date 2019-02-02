module Avram::Migrator::ColumnTypeOptionHelpers
  alias ColumnType = String.class | Time.class | Int32.class | Int64.class | Bool.class | Float.class | UUID.class

  def column_type(type : String.class)
    "text"
  end

  def column_type(type : Time.class)
    "timestamptz"
  end

  def column_type(type : Int32.class)
    "int"
  end

  def column_type(type : Int64.class)
    "bigint"
  end

  def column_type(type : Bool.class)
    "boolean"
  end

  def column_type(type : Float.class)
    "decimal"
  end

  def column_type(type : Float.class, precision : Int32, scale : Int32)
    "decimal(#{precision},#{scale})"
  end

  def column_type(type : UUID.class)
    "uuid"
  end
end
