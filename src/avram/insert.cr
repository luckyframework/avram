class Avram::Insert
  alias Params = Hash(Symbol, String) | Hash(Symbol, String?) | Hash(Symbol, Nil)

  def initialize(@table : TableName, @params : Params, @column_names : Array(Symbol) = [] of Symbol)
  end

  def statement
    "insert into #{@table}(#{fields}) values(#{values_placeholders}) returning #{returning}"
  end

  private def returning : String
    if @column_names.empty?
      "*"
    else
      @column_names.join(", ") { |column| "#{@table}.#{column}" }
    end
  end

  def args
    @params.values
  end

  private def fields
    @params.keys.join(", ")
  end

  private def values_placeholders
    @params.values.map_with_index do |_value, index|
      "$#{index + 1}"
    end.join(", ")
  end
end
