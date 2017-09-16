class LuckyRecord::BaseQueryTemplate
  macro setup(model_type, fields, table_name)
    class BaseQuery < LuckyRecord::Query
      include LuckyRecord::Queryable({{ model_type }})

      @@table_name = {{ table_name }}
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
          \{{ type }}::Criteria(\{{ query_class }}, \{{ type }}).new(self, :\{{ name }})
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
    end
  end
end
