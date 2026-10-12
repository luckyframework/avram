module Avram::Migrator::IndexStatementHelpers
  alias Columns = Symbol | Array(Symbol)

  private getter index_statements = [] of String

  def add_index(column : Symbol, unique = false, using : Symbol = :btree, where : Avram::Queryable? = nil, where_raw : String? = nil)
    index = CreateIndexStatement.new(@table_name, column, using, unique, where: index_where_predicate(where, where_raw)).build
    index_statements << index unless index_added?(index, column)
  end

  # `where_raw` is dropped into the index predicate unescaped — the caller owns its safety.
  private def index_where_predicate(where : Avram::Queryable?, where_raw : String?) : String?
    raise ArgumentError.new("Pass `where:` or `where_raw:`, not both") if where && where_raw
    where ? where.to_prepared_where_sql : where_raw
  end

  # Returns false unless matching index exists. Ignores UNIQUE
  def index_added?(index : String, column : Symbol)
    return false unless index_statements.includes?(index) || index_statements.includes?(index.gsub(" UNIQUE", ""))
    raise "index on #{@table_name}.#{column} already exists"
  end
end
