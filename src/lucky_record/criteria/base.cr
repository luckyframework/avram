class LuckyRecord::Criteria(T, V)
  property :rows, :column

  def initialize(@rows : T, @column : Symbol)
  end

  def is(value : V | String)
    rows.query.where(LuckyRecord::Where::Equal.new(column, value.to_s))
    rows
  end

  def is_not(value : V | String)
    rows.query.where(LuckyRecord::Where::NotEqual.new(column, value.to_s))
    rows
  end

  def gt(value : V | String)
    rows.query.where(LuckyRecord::Where::GreaterThan.new(column, value.to_s))
    rows
  end

  def gte(value : V | String)
    rows.query.where(LuckyRecord::Where::GreaterThanOrEqualTo.new(column, value.to_s))
    rows
  end

  def lt(value : V | String)
    rows.query.where(LuckyRecord::Where::LessThan.new(column, value.to_s))
    rows
  end

  def lte(value : V | String)
    rows.query.where(LuckyRecord::Where::LessThanOrEqualTo.new(column, value.to_s))
    rows
  end
end
