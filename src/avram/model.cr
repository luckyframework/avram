require "db"
require "levenshtein"
require "./schema_enforcer"

class Avram::Model
  include Avram::Associations

  SETUP_STEPS = [] of Nil
  # This setting is used to show better errors
  MACRO_CHECKS = {setup_complete: false}

  macro register_setup_step(call)
    {% if MACRO_CHECKS[:setup_complete] %}
      {% call.raise "Models have already been set up. Make sure to register set up steps before models are required." %}
    {% else %}
      {% SETUP_STEPS << call %}
    {% end %}
  end

  register_setup_step Avram::Model.setup_table_name
  register_setup_step Avram::Model.setup_initialize
  register_setup_step Avram::Model.setup_db_mapping
  register_setup_step Avram::Model.setup_getters
  register_setup_step Avram::Model.setup_column_names_method
  register_setup_step Avram::BaseQueryTemplate.setup
  register_setup_step Avram::SaveOperationTemplate.setup
  register_setup_step Avram::SchemaEnforcer.setup

  macro inherited
    COLUMNS = [] of {name: Symbol, type: Object, nilable: Bool, autogenerated: Bool}
    ASSOCIATIONS = [] of {name: Symbol, foreign_key: Symbol, type: Object, through: Object, relationship_type: Symbol}

    macro finished
      \{% for assoc in ASSOCIATIONS %}
         \{% if assoc[:relationship_type] == :has_many %}
           define_has_many_base_query(
             assoc_name: \{{ assoc[:name] }},
             model: \{{ assoc[:type] }},
             foreign_key: \{{ assoc[:foreign_key].id }},
             through: \{{ assoc[:through] }}
           )
          \{% end %}
      \{% end %}
    end
  end

  def_equals @id

  def to_param
    id.to_s
  end

  macro table(table_name = nil)
    {% unless table_name %}
      {% table_name = run("../run_macros/infer_table_name.cr", @type.id) %}
    {% end %}

    default_columns

    {{ yield }}

    setup({{table_name}})
    {% MACRO_CHECKS[:setup_complete] = true %}
  end

  macro primary_key(type_declaration)
    PRIMARY_KEY_TYPE = {{ type_declaration.type }}
    column {{ type_declaration.var }} : {{ type_declaration.type }}, autogenerated: true
    alias PrimaryKeyType = {{ type_declaration.type }}

    def self.primary_key_name : String
      {{ type_declaration.var.stringify }}
    end

    def primary_key_name : String
      self.class.primary_key_name
    end
  end

  macro default_columns
    primary_key id : Int64
    timestamps
  end

  macro skip_default_columns
    macro default_columns
    end
  end

  macro timestamps
    column created_at : Time, autogenerated: true
    column updated_at : Time, autogenerated: true
  end

  macro setup(table_name)
    {% table_name = table_name.id %}

    {% for step in SETUP_STEPS %}
      {{ step.id }}(
        type: {{ @type }},
        table_name: {{ table_name }},
        primary_key_type: {{ PRIMARY_KEY_TYPE }},
        columns: {{ COLUMNS }},
        associations: {{ ASSOCIATIONS }}
      )
    {% end %}
  end

  def delete
    Avram::Repo.run do |db|
      db.exec "DELETE FROM #{@@table_name} WHERE id = #{id}"
    end
  end

  macro setup_table_name(table_name, *args, **named_args)
    @@table_name = :{{table_name}}
    TABLE_NAME = :{{table_name}}
  end

  macro setup_initialize(columns, *args, **named_args)
    def initialize(
        {% for column in columns %}
          @{{column[:name]}},
        {% end %}
      )
    end
  end

  # Setup [database mapping](http://crystal-lang.github.io/crystal-db/api/0.5.0/DB.html#mapping%28properties%2Cstrict%3Dtrue%29-macro) for the model's columns.
  #
  # NOTE: Avram::Migrator saves `Float` columns as numeric which need to be
  # converted from [PG::Numeric](https://github.com/will/crystal-pg/blob/master/src/pg/numeric.cr) back to `Float64` using a `convertor`
  # class.
  macro setup_db_mapping(columns, *args, **named_args)
    DB.mapping({
      {% for column in columns %}
        {{column[:name]}}: {
          {% if column[:type].id == Float64.id %}
            type: PG::Numeric,
            convertor: Float64Convertor,
          {% else %}
            type: {{column[:type]}}::Lucky::ColumnType,
          {% end %}
          nilable: {{column[:nilable]}},
        },
      {% end %}
    })
  end

  module Float64Converter
    def self.from_rs(rs)
      rs.read(PG::Numeric).to_f
    end
  end

  macro setup_getters(columns, *args, **named_args)
    {% for column in columns %}
      def {{column[:name]}}
        {{ column[:type] }}::Lucky.from_db! @{{column[:name]}}
      end
    {% end %}
  end

  macro column(type_declaration, autogenerated = false)
    {% if type_declaration.type.is_a?(Union) %}
      {% data_type = "#{type_declaration.type.types.first}".id %}
      {% nilable = true %}
    {% else %}
      {% data_type = "#{type_declaration.type}".id %}
      {% nilable = false %}
    {% end %}
    {% COLUMNS << {name: type_declaration.var, type: data_type, nilable: nilable.id, autogenerated: autogenerated} %}
  end

  macro setup_column_names_method(columns, *args, **named_args)
    def self.column_names : Array(Symbol)
      [
        {% for column in columns %}
          :{{column[:name]}},
        {% end %}
      ]
    end
  end

  macro association(table_name, type, relationship_type, foreign_key = nil, through = nil)
    {% ASSOCIATIONS << {type: type, name: table_name.id, foreign_key: foreign_key, relationship_type: relationship_type, through: through} %}
  end
end
