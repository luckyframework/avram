module Avram
  class OrderByRandom < OrderByClause
    def_clone

    def prepare : String
      "RANDOM ()"
    end

    def reversed : self
      self
    end

    def uid : String
      "random"
    end
  end
end
