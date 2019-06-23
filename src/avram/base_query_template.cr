class Avram::BaseQueryTemplate
  macro setup(type, columns, associations, table_name, *args, **named_args)
    class ::{{ type }}::BaseQuery < Avram::Query
      include Avram::Queryable({{ type }})

      @@table_name = :{{ table_name }}
      @@schema_class = {{ type }}

      macro generate_criteria_method(query_class, name, type)
        def \{{ name }}
          column_name = "#{@@table_name}.\{{ name }}"
          \{{ type }}::Lucky::Criteria(\{{ query_class }}, \{{ type }}).new(self, "#{@@table_name}.\{{ name }}")
        end
      end

      {% for column in columns %}
        def {{ column[:name] }}(value)
          {{ column[:name] }}.eq(value)
        end

        generate_criteria_method(BaseQuery, {{ column[:name] }}, {{ column[:type] }})

        macro inherited
          generate_criteria_method(\{{ @type.name }}, {{ column[:name] }}, {{ column[:type] }})
        end
      {% end %}

      {% for assoc in associations %}
        def join_{{ assoc[:name] }}
          inner_join_{{ assoc[:name] }}
        end

        {% for join_type in ["Inner", "Left"] %}
          def {{ join_type.downcase.id }}_join_{{ assoc[:name] }}
            {% if assoc[:relationship_type] == :belongs_to %}
              join(Avram::Join::{{ join_type.id }}.new(@@table_name, :{{ assoc[:name] }}, {{ assoc[:foreign_key] }}, :id))
            {% elsif assoc[:through] %}
              {{ join_type.downcase.id }}_join_{{ assoc[:through].id }}
              {{ assoc[:through].id }} do |join_query|
                join_query.{{ join_type.downcase.id }}_join_{{ assoc[:name] }}
              end
            {% else %}
              join(Avram::Join::{{ join_type.id }}.new(@@table_name, :{{ assoc[:name] }}, foreign_key: {{ assoc[:foreign_key] }}))
            {% end %}
          end
        {% end %}


        def {{ assoc[:name] }}
          {{ assoc[:type] }}::BaseQuery.new_with_existing_query(query).tap do |assoc_query|
            yield assoc_query
          end
          self
        end
      {% end %}
    end
  end
end
