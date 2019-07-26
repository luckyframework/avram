module Avram::Queryable(T)
  include Enumerable(T)

  abstract def id

  @query : Avram::QueryBuilder?
  setter query

  macro included
    def self.new_with_existing_query(query : Avram::QueryBuilder)
      new.tap do |queryable|
        queryable.query = query
      end
    end

    def self.all
      new
    end

    def self.find(id)
      new.find(id)
    end

    def self.first
      new.first
    end

    def self.first?
      new.first?
    end

    def self.last
      new.last
    end

    def self.last?
      new.last?
    end
  end

  def query
    @query ||= Avram::QueryBuilder
      .new(table: @@table_name)
      .select(@@schema_class.column_names)
  end

  def distinct
    query.distinct
    self
  end

  def distinct_on(&block)
    criteria = yield self
    criteria.distinct_on
    self
  end

  # returns the number of records removed as `Int64`.
  # This will run a `DELETE FROM` on the current table
  # with any `WHERE` queries specified. If none are provided,
  # it will delete all records from the table.
  #
  # ```
  # # DELETE FROM users WHERE age < 21
  # UserQuery.new.age.lt(21).delete
  # ```
  def delete : Int64
    query.delete
    database.run do |db|
      db.exec(query.statement, query.args).rows_affected
    end
  end

  def join(join_clause : Avram::Join::SqlClause)
    query.join(join_clause)
    self
  end

  def where(column : Symbol, value)
    query.where(Avram::Where::Equal.new(column, value.to_s))
    self
  end

  def where(statement : String, *bind_vars)
    query.raw_where(Avram::Where::Raw.new(statement, *bind_vars))
    self
  end

  def order_by(column, direction)
    query.order_by(column, direction)
    self
  end

  def none
    query.where(Avram::Where::Equal.new("1", "0"))
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
    ordered_query.limit(1)
    results.first?
  end

  def first
    first? || raise RecordNotFoundError.new(model: @@table_name, query: :first)
  end

  def last?
    ordered_query.reverse_order.limit(1)
    results.first?
  end

  def last
    last? || raise RecordNotFoundError.new(model: @@table_name, query: :last)
  end

  def select_count : Int64
    query.select_count
    exec_scalar.as(Int64)
  end

  def each
    results.each do |result|
      yield result
    end
  end

  getter preloads = [] of Array(T) -> Nil

  def add_preload(&block : Array(T) -> Nil)
    @preloads << block
  end

  def results : Array(T)
    exec_query.tap do |records|
      preloads.each(&.call(records))
    end
  end

  private def exec_query
    database.run do |db|
      db.query query.statement, query.args do |rs|
        @@schema_class.from_rs(rs)
      end
    end
  end

  def exec_scalar
    database.run do |db|
      db.scalar query.statement, query.args
    end
  end

  private def ordered_query
    if query.ordered?
      query
    else
      id.asc_order.query
    end
  end

  def to_sql
    query.to_sql
  end
end
