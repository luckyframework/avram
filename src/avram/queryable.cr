module Avram::Queryable(T)
  include Enumerable(T)
  def_clone

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

  def distinct : self
    clone.distinct!
  end

  protected def distinct! : self
    query.distinct
    self
  end

  def reset_order : self
    clone.reset_order!
  end

  protected def reset_order! : self
    query.reset_order
    self
  end

  def reset_limit : self
    clone.reset_limit!
  end

  protected def reset_limit! : self
    query.limit(nil)
    self
  end

  def reset_offset : self
    clone.reset_offset!
  end

  protected def reset_offset! : self
    query.offset(nil)
    self
  end

  def distinct_on(&block) : self
    criteria = yield self
    criteria.private_distinct_on
    self
  end

  def reset_where(&block) : self
    criteria = yield self
    criteria.private_reset_where
    self
  end

  # Delete the records using the query's where clauses, or all records if no wheres are added.
  #
  # Returns the number of deleted records as `Int64`.
  #
  # ```
  # # DELETE FROM users WHERE age < 21
  # UserQuery.new.age.lt(21).delete
  # ```
  def delete : Int64
    query.delete
    database.exec(query.statement, args: query.args).rows_affected
  end

  # Update the records using the query's where clauses, or all records if no wheres are added.
  #
  # Returns the number of records updated as `Int64`.
  #
  # ```
  # # Update all comments with the word "spam" as spam
  # CommentQuery.new.body.ilike("spam").update(spam: true)
  # ```
  abstract def update : Int64

  def join(join_clause : Avram::Join::SqlClause) : self
    query.join(join_clause)
    self
  end

  def where(column : Symbol, value) : self
    query.where(Avram::Where::Equal.new(column, value.to_s))
    self
  end

  def where(statement : String, *bind_vars) : self
    where(statement, args: bind_vars.to_a)
  end

  def where(statement : String, *, args bind_vars : Array) : self
    query.raw_where(Avram::Where::Raw.new(statement, args: bind_vars))
    self
  end

  def order_by(column, direction) : self
    direction = Avram::OrderBy::Direction.parse(direction.to_s)
    query.order_by(Avram::OrderBy.new(column, direction))
    self
  rescue e : ArgumentError
    raise "#{e.message}. Accepted values are: :asc, :desc"
  end

  def group(&block) : self
    criteria = yield self
    criteria.private_group
    self
  end

  def none : self
    query.where(Avram::Where::Equal.new("1", "0"))
    self
  end

  def limit(amount) : self
    query.limit(amount)
    self
  end

  def offset(amount) : self
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
  rescue e : DB::NoResultsError
    0_i64
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
    database.query query.statement, args: query.args, queryable: @@schema_class.name do |rs|
      @@schema_class.from_rs(rs)
    end
  end

  def exec_scalar
    database.scalar query.statement, args: query.args, queryable: @@schema_class.name
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

  def to_prepared_sql
    query.to_prepared_sql
  end
end
