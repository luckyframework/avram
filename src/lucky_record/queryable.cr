module LuckyRecord::Queryable(T)
  include Enumerable(T)

  @query : LuckyRecord::QueryBuilder?

  macro included
    def self.all
      new
    end
  end

  def query
    @query ||= LuckyRecord::QueryBuilder
      .new(table: @@table_name)
      .select(@@schema_class.column_names)
  end

  def join(join_clause : LuckyRecord::Join::SqlClause)
    query.join(join_clause)
    self
  end

  def where(column : Symbol, value)
    query.where(LuckyRecord::Where::Equal.new(column, value.to_s))
    self
  end

  def where(statement : String, *bind_vars)
    query.raw_where(LuckyRecord::Where::Raw.new(statement, *bind_vars))
    self
  end

  def order_by(column, direction)
    query.order_by(column, direction)
    self
  end

  def limit(amount)
    query.limit(amount)
    self
  end

  def offset(amount)
    query.offset(amount)
    self
  end

  def find(id)
    id(id).limit(1).first? || raise RecordNotFoundError.new(model: @@table_name, id: id.to_s)
  end

  def first?
    query.limit(1)
    exec_query.first?
  end

  def first
    first? || raise RecordNotFoundError.new(model: @@table_name, query: :first)
  end

  def last?
    ordered_query.reverse_order.limit(1)
    exec_query.first?
  end

  def last
    last? || raise RecordNotFoundError.new(model: @@table_name, query: :last)
  end

  def count : Int64
    query.count
    exec_scalar.as(Int64)
  end

  def each
    results.each do |result|
      yield result
    end
  end

  def results
    exec_query
  end

  private def exec_query
    LuckyRecord::Repo.run do |db|
      db.query query.statement, query.args do |rs|
        @@schema_class.from_rs(rs)
      end
    end
  end

  private def exec_scalar
    LuckyRecord::Repo.run do |db|
      db.scalar query.statement, query.args
    end
  end

  private def ordered_query
    if query.ordered?
      query
    else
      query.order_by(:id, :asc)
    end
  end

  def to_sql
    query.to_sql
  end
end
