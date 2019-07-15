module Avram::Migrator::IndexStatementHelpers
  alias Columns = Symbol | Array(Symbol)

  private getter index_statements = [] of String

  # Generates raw sql for adding an index to a table column. Accepts 'unique' and 'using' options.
  def add_index(column : Columns, unique = false, using : Symbol = :btree)
    index = CreateIndexStatement.new(@table_name, column, using, unique).build
    index_statements << index unless index_added?(index, column)
  end

  def drop_index(column : Columns, if_exists = false, on_delete = :do_nothing)
    index = DropIndexStatement.new(@table_name, column, if_exists, on_delete).build
    index_statements << index
  end

  # Returns false unless matching index exists. Ignores UNIQUE
  def index_added?(index : String, column : Columns)
    return false unless index_statements.includes?(index) || index_statements.includes?(index.gsub(" UNIQUE", ""))
    raise "index on #{@table_name}.#{column} already exists"
  end
end
