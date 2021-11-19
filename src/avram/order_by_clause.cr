module Avram
  abstract class OrderByClause
    abstract def prepare : String
    abstract def reversed : self
    abstract def uid : String
  end
end
