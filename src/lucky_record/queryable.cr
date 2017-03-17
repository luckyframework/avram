module LuckyRecord::Queryable
  @limit : Int32 | Nil
  @wheres = {} of Symbol => (String | Int32)

  macro included
    def self.all
      new
    end
  end

  def where(attrs)
    @wheres.merge!(attrs.to_h)
    self
  end

  private def wheres_sql
    if @wheres.empty?
      ""
    else
      " WHERE " + @wheres.map do |key, value|
        "#{key} = #{escape_sql(value)}"
      end.join(" AND ")
    end
  end

  def limit(limit_number)
    @limit = limit_number
    self
  end

  private def limit_sql
    if @limit
      " LIMIT #{@limit}"
    else
      ""
    end
  end

  def limit(limit_number)
    @limit = limit_number
    self
  end

  private def limit_sql
    if @limit
      " LIMIT #{@limit}"
    else
      ""
    end
  end

  def find(id)
    query(where({id: id}).limit(1).to_sql).first
  end

  def first
    query(limit(1).to_sql).first
  end

  def to_a
    query(to_sql)
  end

  def query(sql)
    LuckyRecord::Repo.run do |db|
      db.query sql do |rs|
        @@schema_class.from_rs(rs)
      end
    end
  end

  def to_sql
    "SELECT * FROM #{@@table_name}" + wheres_sql + limit_sql
  end
end
