class LuckyRecord::Criteria(T, V)
  property :rows, :column

  def initialize(@rows : T, @column : Symbol)
  end

  def desc_order
    rows.query.order_by(column, :desc)
    rows
  end

  def asc_order
    rows.query.order_by(column, :asc)
    rows
  end

  def is(value)
    rows.query.where(LuckyRecord::Where::Equal.new(column, V.cast_and_serialize(value)))
    rows
  end

  def is_not(value)
    rows.query.where(LuckyRecord::Where::NotEqual.new(column, V.cast_and_serialize(value)))
    rows
  end

  def gt(value)
    rows.query.where(LuckyRecord::Where::GreaterThan.new(column, V.cast_and_serialize(value)))
    rows
  end

  def gte(value)
    rows.query.where(LuckyRecord::Where::GreaterThanOrEqualTo.new(column, V.cast_and_serialize(value)))
    rows
  end

  def lt(value)
    rows.query.where(LuckyRecord::Where::LessThan.new(column, V.cast_and_serialize(value)))
    rows
  end

  def lte(value)
    rows.query.where(LuckyRecord::Where::LessThanOrEqualTo.new(column, V.cast_and_serialize(value)))
    rows
  end
end
