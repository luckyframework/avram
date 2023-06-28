class Avram::Insert
  alias Params = Array(Hash(Symbol, String)) | Array(Hash(Symbol, String?)) | Array(Hash(Symbol, Nil))

  def initialize(@table : TableName, @params : Params, @column_names : Array(Symbol) = [] of Symbol)
  end

  def statement
    "insert into #{@table}(#{fields}) values #{values_sql_fragment} returning #{returning}"
  end

  private def returning : String
    if @column_names.empty?
      "*"
    else
      @column_names.join(", ") { |column| "#{@table}.#{column}" }
    end
  end

  def args
    @params.flat_map(&.values)
  end

  private def fields
    @params.first.keys.join(", ")
  end

  private def values_sql_fragment
    @params.map_with_index { |params, offset| values_placeholders(params, offset * params.size) }.join(", ")
  end

  private def values_placeholders(params, offset = 0)
    String.build do |io|
      io << "("
      io << params.values.map_with_index { |_v, index| "$#{offset + index + 1}" }.join(", ")
      io << ")"
    end
  end
end
