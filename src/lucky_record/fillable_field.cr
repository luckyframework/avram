require "./field"

module LuckyRecord::Fillable
  abstract def name
  abstract def value
  abstract def form_name
  abstract def errors
  abstract def valid?
  abstract def changed?
end

class LuckyRecord::FillableField(T) < LuckyRecord::Field(T)
  include LuckyRecord::Fillable
end
