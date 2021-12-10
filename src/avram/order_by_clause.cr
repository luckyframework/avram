module Avram
  abstract class OrderByClause
    abstract def column : String | Symbol
    abstract def prepare : String
    abstract def reversed : self
  end
end
