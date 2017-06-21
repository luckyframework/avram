class LuckyRecord::Criteria(T, V)
  property :rows, :column

  def initialize(@rows : T, @column : Symbol)
  end

  def is(value : V::BaseType | String)
    rows.query.where(LuckyRecord::Where::Equal.new(column, V.serialize(value)))
    rows
  end

  def is_not(value : V::BaseType | String)
    rows.query.where(LuckyRecord::Where::NotEqual.new(column, V.serialize(value)))
    rows
  end

  def gt(value : V::BaseType | String)
    rows.query.where(LuckyRecord::Where::GreaterThan.new(column, V.serialize(value)))
    rows
  end

  def gte(value : V::BaseType | String)
    rows.query.where(LuckyRecord::Where::GreaterThanOrEqualTo.new(column, V.serialize(value)))
    rows
  end

  def lt(value : V::BaseType | String)
    rows.query.where(LuckyRecord::Where::LessThan.new(column, V.serialize(value)))
    rows
  end

  def lte(value : V::BaseType | String)
    rows.query.where(LuckyRecord::Where::LessThanOrEqualTo.new(column, V.serialize(value)))
    rows
  end
end
