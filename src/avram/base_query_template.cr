class Avram::BaseQueryTemplate
  macro setup(type, columns, associations, *args, **named_args)
    class ::{{ type }}::BaseQuery
      def_clone
      include Avram::Queryable({{ type }})

      {% if type.resolve.has_constant?("PRIMARY_KEY_NAME") %}
        include Avram::PrimaryKeyQueryable({{ type }})
      {% end %}

      macro generate_criteria_method(name, type)
        def \{{ name }}
          \{{ type }}.adapter.criteria(self, "#{table_name}.\{{ name }}")
        end
      end

      def update(
          {% for column in columns %}
            {{ column[:name] }} : {{ column[:type] }} | Avram::Nothing{% if column[:nilable] %} | Nil{% end %} = Avram::Nothing.new,
          {% end %}
        ) : Int64

        _changes = {} of Symbol => String?

        {% for column in columns %}
          if {{ column[:name] }}.nil?
            _changes[:{{ column[:name] }}] = nil
          elsif {{ column[:name] }}.is_a?(Avram::Nothing)
            nil
          else
            value = {{ column[:name] }}.not_nil!.class.adapter.to_db({{ column[:name] }}).to_s
            _changes[:{{ column[:name] }}] = value
          end
        {% end %}

        database.exec(
          query.statement_for_update(_changes, return_columns: false),
          args: query.args_for_update(_changes)
        ).rows_affected
      end

      {% for column in columns %}
        def {{ column[:name] }}(value)
          {{ column[:name] }}.eq(value)
        end

        generate_criteria_method({{ column[:name] }}, {{ column[:type] }})

        macro inherited
          generate_criteria_method({{ column[:name] }}, {{ column[:type] }})
        end
      {% end %}

      {% for assoc in associations %}
        def join_{{ assoc[:assoc_name] }}
          inner_join_{{ assoc[:assoc_name] }}
        end

        {% for join_type in ["Inner", "Left", "Right", "Full"] %}
          def {{ join_type.downcase.id }}_join_{{ assoc[:assoc_name] }}
            {% if assoc[:relationship_type] == :belongs_to %}
              join(
                Avram::Join::{{ join_type.id }}.new(
                  from: table_name,
                  to: {{ assoc[:type] }}.table_name,
                  primary_key: {{ assoc[:foreign_key].id.symbolize }},
                  foreign_key: {{ assoc[:type] }}::PRIMARY_KEY_NAME
                )
              )
            {% elsif assoc[:relationship_type] == :has_one %}
              join(
                Avram::Join::{{ join_type.id }}.new(
                  from: table_name,
                  to: {{ assoc[:type] }}.table_name,
                  foreign_key: {{ assoc[:foreign_key].id.symbolize }},
                  primary_key: primary_key_name
                )
              )
            {% elsif assoc[:through] %}
              {{ join_type.downcase.id }}_join_{{ assoc[:through].first.id }}
                .__yield_where_{{ assoc[:through].first.id }} do |join_query|
                  join_query.{{ join_type.downcase.id }}_join_{{ assoc[:through][1].id }}
                end
            {% else %}
              join(
                Avram::Join::{{ join_type.id }}.new(
                  from: table_name,
                  to: {{ assoc[:type] }}.table_name,
                  foreign_key: {{ assoc[:foreign_key] }},
                  primary_key: primary_key_name
                )
              )
            {% end %}
          end
        {% end %}


        def where_{{ assoc[:assoc_name] }}(assoc_query : {{ assoc[:type] }}::BaseQuery, auto_inner_join : Bool = true)
          if auto_inner_join
            join_{{ assoc[:assoc_name] }}.merge_query(assoc_query.query)
          else
            merge_query(assoc_query.query)
          end
        end

        # :nodoc:
        # Used internally for has_many through queries
        def __yield_where_{{ assoc[:assoc_name] }}
          assoc_query = yield {{ assoc[:type] }}::BaseQuery.new
          merge_query(assoc_query.query)
        end
      {% end %}
    end
  end
end
