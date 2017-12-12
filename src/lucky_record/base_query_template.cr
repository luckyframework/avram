class LuckyRecord::BaseQueryTemplate
  macro setup(model_type, fields, associations, table_name)
    class BaseQuery < LuckyRecord::Query
      include LuckyRecord::Queryable({{ model_type }})

      @@table_name = :{{ table_name }}
      @@schema_class = {{ model_type }}

      def field_names
        [
          {% for field in fields %}
            {{field[:name]}},
          {% end %}
        ]
      end

      macro generate_criteria_method(query_class, name, type)
        def \{{ name }}
          \{{ type }}::Lucky::Criteria(\{{ query_class }}, \{{ type }}).new(self, :\{{ name }})
        end
      end

      {% for field in fields %}
        def {{ field[:name] }}(value)
          where(:{{ field[:name] }}, value)
        end

        generate_criteria_method(BaseQuery, {{ field[:name] }}, {{ field[:type] }})

        macro inherited
          generate_criteria_method(\{{ @type.name }}, {{ field[:name] }}, {{ field[:type] }})
        end
      {% end %}

      {% for assoc in associations %}
        def join_{{ assoc[:name] }}
          inner_join_{{ assoc[:name] }}
        end

        def inner_join_{{ assoc[:name] }}
          join(LuckyRecord::Join::Inner.new(@@table_name, :{{ assoc[:name] }}, foreign_key: {{ assoc[:foreign_key] }}))
        end

        def left_join_{{ assoc[:name] }}
          join(LuckyRecord::Join::Inner.new(@@table_name, :{{ assoc[:name] }}, foreign_key: {{ assoc[:foreign_key] }}))
        end
      {% end %}
    end
  end
end
