class Avram::BulkUpsert
  alias Params = Hash(Symbol, String) | Hash(Symbol, String?) | Hash(Symbol, Nil)

  def initialize(@table : TableName,
                 @records : Array(Params),
                 @column_names : Array(Symbol) = [] of Symbol)
  end

  def statement
    "insert into #{@table}(#{fields}) values(#{values}) returning *"
  end

  private def fields
    @column_names.join(", ")
  end

  private def record_values(record)
    values = record.values.map_with_index(1) do |_value, index|
      "$#{index}"
    end.join(", ")

    "(#{values})"
  end

  private def values
    @records.map do |record|
      record_values(record)
    end.join(", ")
  end
end
