class LuckyRecord::Schema
  macro inherited
    FIELDS = [] of {name: Symbol, type: Object, nilable: Boolean}

    field :id, Int32
    field :created_at, Time
    field :updated_at, Time
  end

  def_equals @id

  macro table(table_name)
    {{yield}}
    setup {{table_name}}
  end

  macro setup(table_name)
    setup_initialize
    setup_db_mapping
    setup_abstract_row_class({{table_name}})
    setup_table_name({{table_name}})
  end

  macro setup_table_name(table_name)
    @@table_name = {{table_name}}
  end

  macro setup_initialize
    def initialize(
        {% for field in FIELDS %}
          @{{field[:name].id}} : {{field[:type]}}{% if field[:nilable] %}?{% end %},
        {% end %}
      )
    end
  end

  macro setup_db_mapping
    DB.mapping({
      {% for field in FIELDS %}
        {{field[:name].id}}: {
          type: {{field[:type].id}},
          nilable: {{field[:nilable].id}},
        },
      {% end %}
    })
  end

  macro setup_abstract_row_class(table_name)
    abstract class BaseRows < LuckyRecord::Rows
      include LuckyRecord::Queryable

      @@table_name = {{table_name}}
      @@schema_class = {{@type}}

      def field_names
        [
          {% for field in FIELDS %}
            {{field[:name]}},
          {% end %}
        ]
      end

      private def escape_sql(value : String)
        PG::EscapeHelper.escape_literal(value)
      end

      private def escape_sql(value : Int32)
        value
      end
    end
  end

  macro field(name)
    {% FIELDS << {name: name, type: String, nilable: false} %}
    property {{name.id}} : String
  end

  macro field(name, type, nilable = false)
    {% FIELDS << {name: name, type: type, nilable: nilable} %}
    property {{name.id}} : {{type}}{% if nilable %}?{% end %}
  end
end
