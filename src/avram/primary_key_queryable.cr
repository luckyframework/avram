require "./errors"
require "./queryable"

module Avram::PrimaryKeyQueryable(T)
  abstract def id
  abstract def id(id_val)

  macro included
    include Avram::Queryable(T)

    def self.find(id)
      new.find(id)
    end

    def find(id)
      id(id).limit(1).first? || raise Avram::RecordNotFoundError.new(model: @@table_name, id: id.to_s)
    end

    private def with_ordered_query : self
      if query.ordered?
        self
      else
        id.asc_order
      end
    end
  end
end
