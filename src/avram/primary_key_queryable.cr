require "./errors"

module Avram::PrimaryKeyQueryable(T)
  macro included
    def self.find(id)
      new.find(id)
    end

    def find(id)
      id(id).first? || raise Avram::RecordNotFoundError.new(model: table_name, id: id.to_s)
    end

    {% primary_key_name = T.constant("PRIMARY_KEY_NAME") %}
    # If not using default 'id' primary key
    {% if primary_key_name.id != "id".id %}
      # Then point 'id' to the primary key
      def id(*args, **named_args)
        {{ primary_key_name.id }}(*args, **named_args)
      end
    {% end %}

    private def with_ordered_query : self
      if query.ordered?
        self
      else
        id.asc_order
      end
    end
  end
end
