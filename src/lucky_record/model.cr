class LuckyRecord::Model
  macro inherited
    FIELDS = [] of {name: Symbol, type: Object, nilable: Boolean}

    field id : Int32
    field created_at : Time
    field updated_at : Time
  end

  def_equals @id

  def to_param
    id.to_s
  end

  macro table(table_name)
    {{yield}}
    setup {{table_name}}
  end

  macro setup(table_name)
    setup_initialize
    setup_db_mapping
    setup_getters
    setup_base_query_class({{table_name}})
    setup_base_form_class({{table_name}})
    setup_table_name({{table_name}})
  end

  macro setup_table_name(table_name)
    @@table_name = {{table_name}}
  end

  macro setup_initialize
    def initialize(
        {% for field in FIELDS %}
          @{{field[:name]}} : {{field[:type]}}::BaseType{% if field[:nilable] %}?{% end %},
        {% end %}
      )
    end
  end

  macro setup_db_mapping
    DB.mapping({
      {% for field in FIELDS %}
        {{field[:name]}}: {
          type: {{field[:type]}}::BaseType,
          nilable: {{field[:nilable]}},
        },
      {% end %}
    })
  end

  macro setup_base_query_class(table_name)
    LuckyRecord::BaseQueryTemplate.setup({{ @type }}, {{ FIELDS }}, {{ table_name }})
  end

  macro setup_base_form_class(table_name)
    LuckyRecord::BaseFormTemplate.setup({{ @type }}, {{ FIELDS }}, {{ table_name }})
  end

  macro setup_getters
    {% for field in FIELDS %}
      def {{field[:name]}}
        {{ field[:type] }}.deserialize @{{field[:name]}}
      end
    {% end %}
  end

  macro field(type_declaration)
    {% if type_declaration.type.is_a?(Union) %}
      {% data_type = "LuckyRecord::#{type_declaration.type.types.first}Type".id }
      {% nilable = true %}
    {% else %}
      {% data_type = "LuckyRecord::#{type_declaration.type}Type".id }
      {% nilable = false %}
    {% end %}
    {% FIELDS << {name: type_declaration.var, type: data_type, nilable: nilable.id} %}
  end
end
