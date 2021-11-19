module Avram
  class OrderByRandom < OrderByClause
    def_clone

    getter column : String | Symbol = "*"

    def prepare : String
      "RANDOM ()"
    end

    def reversed : self
      self
    end
  end
end
