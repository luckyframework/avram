class Avram::Insert
  alias Params = Hash(Symbol, String) | Hash(Symbol, String?) | Hash(Symbol, Nil)

  enum ConflictAction
    Nothing
    Update

    def to_s(io : IO)
      case self
      in .nothing?
        io << "NOTHING"
      in .update?
        io << "UPDATE"
      end
    end
  end

  def initialize(
    @table : TableName,
    @params : Params,
    @column_names = [] of Symbol,
    @conflict_action : ConflictAction? = nil,
    @conflict_keys = [] of Symbol,
    @conflict_params = [] of Symbol
  )
  end

  def statement : String
    String.build do |io|
      io << "INSERT INTO "
      io << @table
      io << " ("
      fields(io)
      io << ')'
      io << " VALUES ("
      values_placeholders(io)
      io << ')'

      if @conflict_action && !@conflict_keys.empty?
        io << " ON CONFLICT ("
        conflict_keys(io)
        io << ") DO "
        io << @conflict_action

        if @conflict_action.try(&.update?)
          io << " SET "
          excluded_params(io)
        end
      end

      io << " RETURNING "
      returning(io)
    end
  end

  private def returning(io)
    if @column_names.empty?
      io << '*'
    else
      @column_names.join(io, ", ") do |column, _io|
        _io << '"'
        _io << @table
        _io << %(".")
        _io << column
        _io << '"'
      end
    end
  end

  def args
    @params.values
  end

  private def fields(io)
    @params.join(io, ", ") do |(col, _value), _io|
      _io << '"'
      _io << col
      _io << '"'
    end
  end

  private def values_placeholders(io)
    @params.values.map_with_index do |_value, index|
      "$#{index + 1}"
    end.join(io, ", ")
  end

  private def conflict_keys(io)
    @conflict_keys.join(io, ", ") do |col, _io|
      _io << '"'
      _io << col
      _io << '"'
    end
  end

  private def excluded_params(io)
    @conflict_params.join(io, ", ") do |key, _io|
      _io << '"'
      _io << key
      _io << %(" = EXCLUDED.")
      _io << key
      _io << '"'
    end
  end
end
