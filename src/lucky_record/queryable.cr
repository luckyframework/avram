module LuckyRecord::Queryable
  @query : LuckyRecord::Query?

  macro included
    def self.all
      new
    end
  end

  def where(column, value)
    query.where(LuckyRecord::Where::Equal.new(column, value.to_s))
    self
  end

  def limit(amount)
    query.limit(amount)
    self
  end

  def find(id)
    where(:id, id.to_s).limit(1).first
  end

  def first
    query.limit(1)
    exec_query.first
  end

  def to_a
    exec_query
  end

  private def exec_query
    LuckyRecord::Repo.run do |db|
      db.query query_string, query_args do |rs|
        @@schema_class.from_rs(rs)
      end
    end
  end

  def query_string
    to_sql.first
  end

  def query_args
    to_sql.skip(1)
  end

  def to_sql
    query.to_sql
  end

  private def query
    @query ||= LuckyRecord::Query.new(table: @@table_name)
  end
end
