module Avram::Queryable(T)
  include Enumerable(T)

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
      .new(table: table_name)
      .select(@@schema_class.column_names)
  end

  def distinct : self
    clone.tap &.query.distinct
  end

  def reset_order : self
    clone.tap &.query.reset_order
  end

  def reset_limit : self
    clone.tap &.query.limit(nil)
  end

  def reset_offset : self
    clone.tap &.query.offset(nil)
  end

  def distinct_on(&block) : self
    criteria = yield clone
    criteria.private_distinct_on
  end

  def reset_where(&block) : self
    criteria = yield clone
    criteria.private_reset_where
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
    clone.delete!
  end

  protected def delete! : Int64
    new_query = query.clone.delete
    database.exec(new_query.statement, args: new_query.args).rows_affected
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
    clone.tap &.query.join(join_clause)
  end

  def where(column : Symbol, value) : self
    clone.tap &.query.where(Avram::Where::Equal.new(column, value.to_s))
  end

  def where(statement : String, *bind_vars) : self
    where(statement, args: bind_vars.to_a)
  end

  def where(statement : String, *, args bind_vars : Array) : self
    clone.tap &.query.raw_where(Avram::Where::Raw.new(statement, args: bind_vars))
  end

  def where(sql_clause : Avram::Where::SqlClause) : self
    clone.tap &.query.where(sql_clause)
  end

  def merge_query(query_to_merge : Avram::QueryBuilder) : self
    clone.tap &.query.merge(query_to_merge)
  end

  def order_by(column, direction) : self
    direction = Avram::OrderBy::Direction.parse(direction.to_s)
    order_by(Avram::OrderBy.new(column, direction))
  rescue e : ArgumentError
    raise "#{e.message}. Accepted values are: :asc, :desc"
  end

  def order_by(order : Avram::OrderBy) : self
    clone.tap &.query.order_by(order)
  end

  def group(&block) : self
    criteria = yield clone
    criteria.private_group
  end

  def none : self
    clone.tap &.query.where(Avram::Where::Equal.new("1", "0"))
  end

  def limit(amount) : self
    clone.tap &.query.limit(amount)
  end

  def offset(amount) : self
    clone.tap &.query.offset(amount)
  end

  def first?
    with_ordered_query
      .limit(1)
      .results
      .first?
  end

  def first
    first? || raise RecordNotFoundError.new(model: table_name, query: :first)
  end

  def last?
    with_ordered_query
      .clone
      .tap(&.query.reverse_order)
      .limit(1)
      .results
      .first?
  end

  def last
    last? || raise RecordNotFoundError.new(model: table_name, query: :last)
  end

  def select_count : Int64
    exec_scalar(&.select_count).as(Int64)
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

  def exec_scalar(&block)
    new_query = yield query.clone
    database.scalar new_query.statement, args: new_query.args, queryable: @@schema_class.name
  end

  private def with_ordered_query : self
    self
  end

  def to_sql
    query.to_sql
  end

  def to_prepared_sql
    query.to_prepared_sql
  end
end
