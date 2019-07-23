class Avram::BaseQueryTemplate
  macro setup(type, columns, associations, table_name, primary_key_name, *args, **named_args)
    class ::{{ type }}::BaseQuery < Avram::Query
      include Avram::Queryable({{ type }})

      def database
        {{ type }}.database
      end

      @@table_name = :{{ table_name }}
      @@schema_class = {{ type }}

      # If not using default 'id' primary key
      {% if primary_key_name.id != "id".id %}
        # Then point 'id' to the primary key
        def id(*args, **named_args)
          {{ primary_key_name.id }}(*args, **named_args)
        end
      {% end %}

      def primary_key_name
        :{{ primary_key_name.id }}
      end

      macro generate_criteria_method(query_class, name, type)
        def \{{ name }}
          column_name = "#{@@table_name}.\{{ name }}"
          \{{ type }}::Lucky::Criteria(\{{ query_class }}, \{{ type }}).new(self, column_name)
        end
      end

      {% for column in columns %}
        def {{ column[:name] }}(value)
          {{ column[:name] }}.eq(value)
        end

        {% if column[:type].is_a?(Generic) %}
          # Checking Array type
          generate_criteria_method(BaseQuery, {{ column[:name] }}, {{ column[:type].type_vars.first }})

          macro inherited
            generate_criteria_method(\{{ @type.name }}, {{ column[:name] }}, {{ column[:type].type_vars.first }})
          end
        {% else %}
          generate_criteria_method(BaseQuery, {{ column[:name] }}, {{ column[:type] }})

          macro inherited
            generate_criteria_method(\{{ @type.name }}, {{ column[:name] }}, {{ column[:type] }})
          end
        {% end %}
      {% end %}

      {% for assoc in associations %}
        def join_{{ assoc[:table_name] }}
          inner_join_{{ assoc[:table_name] }}
        end

        {% for join_type in ["Inner", "Left", "Right", "Full"] %}
          def {{ join_type.downcase.id }}_join_{{ assoc[:table_name] }}
            {% if assoc[:relationship_type] == :belongs_to %}
              join(
                Avram::Join::{{ join_type.id }}.new(
                  from: @@table_name,
                  to: :{{ assoc[:table_name] }},
                  primary_key: {{ assoc[:foreign_key] }},
                  foreign_key: primary_key_name
                )
              )
            {% elsif assoc[:through] %}
              {{ join_type.downcase.id }}_join_{{ assoc[:through].id }}
              where_{{ assoc[:through].id }} do |join_query|
                join_query.{{ join_type.downcase.id }}_join_{{ assoc[:table_name] }}
              end
            {% else %}
              join(
                Avram::Join::{{ join_type.id }}.new(
                  from: @@table_name,
                  to: :{{ assoc[:table_name] }},
                  foreign_key: {{ assoc[:foreign_key] }},
                  primary_key: primary_key_name
                )
              )
            {% end %}
          end
        {% end %}


        def where_{{ assoc[:table_name] }}
          {{ assoc[:type] }}::BaseQuery.new_with_existing_query(query).tap do |assoc_query|
            yield assoc_query
          end
          self
        end

        def {{ assoc[:table_name] }}
          \{% raise <<-ERROR
            The methods for querying associations are now prefixed with 'where_'

            Try this...

              ▸ Use 'where_{{ assoc[:table_name] }}'
            ERROR
          %}
          yield # This is not used. Just there so it works with blocks.
        end
      {% end %}
    end
  end
end
