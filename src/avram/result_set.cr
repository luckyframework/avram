class Avram::ResultSet < ::DB::ResultSet
  alias AllTypes = (Array(PG::BoolArray) | Array(PG::CharArray) | Array(PG::Float32Array) | Array(PG::Float64Array) | Array(PG::Int16Array) | Array(PG::Int32Array) | Array(PG::Int64Array) | Array(PG::NumericArray) | Array(PG::StringArray) | Array(PG::TimeArray) | Array(PG::UUIDArray) | Bool | Char | DB::Mappable | Float32 | Float64 | Int16 | Int32 | Int64 | JSON::PullParser | PG::Geo::Box | PG::Geo::Circle | PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point | PG::Geo::Polygon | PG::Interval | PG::Numeric | Slice(UInt8) | String | Time | UInt32 | UUID | Nil)
  alias ConvertedTypes = (Array(Bool) | Array(Int16) | Array(Int32) | Array(Int64) | Array(PG::Numeric) | Array(String) | Array(UUID) | Array(PG::BoolArray) | Array(PG::CharArray) | Array(PG::Float32Array) | Array(PG::Float64Array) | Array(PG::Int16Array) | Array(PG::Int32Array) | Array(PG::Int64Array) | Array(PG::NumericArray) | Array(PG::StringArray) | Array(PG::TimeArray) | Array(PG::UUIDArray) | Bool | Char | DB::Mappable | Float32 | Float64 | Int16 | Int32 | Int64 | JSON::PullParser | PG::Geo::Box | PG::Geo::Circle | PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point | PG::Geo::Polygon | PG::Interval | PG::Numeric | Slice(UInt8) | String | Time | UInt32 | UUID | Nil)
  # From RS
  @column_count : Int32
  @column_names : Array(String)

  # Internal Pointers
  @current_row_index : Int32 = -1
  @current_column_index : Int32 = -1
  @table : Array(Array(ConvertedTypes))

  def initialize(@statement : DB::Statement, @rs : PG::ResultSet)
    # From RS
    @column_count = rs.column_count
    @column_names = rs.column_names

    # Internal Pointers
    @table = [] of Array(ConvertedTypes)
    @rs.each do
      # starting to process a new row
      row = Array(ConvertedTypes).new
      @column_count.times do |i|
        read_value = @rs.read
        # type = @rs.column_type(i)
        row << pre_process(read_value)
      end
      @table << row
    end
  end

  def pre_process(value : AllTypes)
    value
  end

  {% for t in ["Bool", "Int16", "Int32", "Int64", "String", "UUID"] %}
  def pre_process(value : Array(PG::{{ t.id }}Array))
    value.map(&.as({{ t.id }}))
  end
  {% end %}

  def pre_process(value : Array(PG::NumericArray))
    value.map(&.as(PG::Numeric))
  end

  protected def do_close
    statement.release_connection
  end

  # TODO add_next_result_set : Bool

  # Iterates over all the rows
  def each
    while move_next
      yield
    end
  end

  # Iterates over all the columns
  def each_column
    column_count.times do |x|
      yield column_name(x)
    end
  end

  # Move the next row in the result.
  # Return `false` if no more rows are available.
  # See `#each`
  def move_next : Bool
    @current_row_index += 1
    @current_column_index = -1
    !!@table[@current_row_index]?
  end

  # TODO def empty? : Bool, handle internally with move_next (?)

  # Returns the number of columns in the result
  def column_count : Int32
    @column_count
  end

  # Returns the name of the column in `index` 0-based position.
  def column_name(index : Int32) : String
    @column_names[index]
  end

  # Returns the name of the columns.
  def column_names
    @column_names
  end

  # Reads the next column value
  def read
    current_row = @table[@current_row_index]?

    if row = current_row
      @current_column_index += 1
      row[@current_column_index]?
    end
  end

  def read(t : String.class) : String
    value = read(String | Slice(UInt8))

    case value
    when Slice(UInt8)
      String.new(value)
    else
      value
    end
  end

  def read(t : String?.class) : String?
    value = read(String | Slice(UInt8) | Nil)

    case value
    when Slice(UInt8)
      String.new(value)
    else
      value
    end
  end

  def read(t : JSON::Any.class) : JSON::Any
    value = read(JSON::PullParser)
    JSON::Any.new(value)
  end

  def read(t : JSON::Any?.class) : JSON::Any?
    value = read(JSON::PullParser?)
    JSON::Any.new(value) if value
  end

  # Returns the column index that corresponds to the next `#read`.
  #
  # If the last column of the current row has been read, it must return `#column_count`.
  def next_column_index : Int32
    0
  end
end
