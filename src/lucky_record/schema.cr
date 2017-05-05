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
    setup_getters
    setup_abstract_row_class({{table_name}})
    setup_abstract_form_class({{table_name}})
    setup_table_name({{table_name}})
  end

  macro setup_table_name(table_name)
    @@table_name = {{table_name}}
  end

  macro setup_initialize
    def initialize(
        {% for field in FIELDS %}
          @{{field[:name].id}} : {{LuckyRecord::Types::TYPE_MAPPINGS[field[:type]]}}{% if field[:nilable] %}?{% end %},
        {% end %}
      )
    end
  end

  macro setup_db_mapping
    DB.mapping({
      {% for field in FIELDS %}
        {{field[:name].id}}: {
          type: {{LuckyRecord::Types::TYPE_MAPPINGS[field[:type]]}},
          nilable: {{field[:nilable].id}},
        },
      {% end %}
    })
  end

  macro setup_abstract_row_class(table_name)
    abstract class BaseRows < LuckyRecord::Rows
      @@table_name = {{table_name}}
      @@schema_class = {{@type}}

      def field_names
        [
          {% for field in FIELDS %}
            {{field[:name]}},
          {% end %}
        ]
      end
    end
  end

  macro setup_abstract_form_class(table_name)
    abstract class BaseForm
      property? performed : Bool = false

      @record : {{@type}}?
      @params : Hash(String, String)
      @valid : Bool = true
      @errors = Hash(Symbol, Array(String)).new(Array(String).new)

      @@table_name = {{table_name}}
      @@allowed_param_keys = [] of String

      def initialize(@params)
        extract_changes_from_params
      end

      private def extract_changes_from_params
        allowed_params.each do |key, value|
          {% for field in FIELDS %}
            set_{{field[:name].id}}_from_param value if key == {{field[:name].id.stringify}}
          {% end %}
        end
      end

      def initialize(@record, @params)
        extract_changes_from_params
      end

      def valid? : Bool
        call
        # TODO: run_auto_generated_validations
        fields.all? &.valid?
      end

      def call
        # TODO add default validate_required for non-nilable fields
      end

      macro allow(*field_names)
        \{% for field_name in field_names %}
          def \{{field_name.id}}
            _\{{field_name.id}}
          end

          @@allowed_param_keys << "\{{field_name.id}}"
        \{% end %}
      end

      def changes
        _changes = {} of Symbol => String?
        fields.each do |field|
          if field.changed?
            _changes[field.name] = field.value.to_s
          end
        end
        _changes
      end

      def save : Bool
        @performed = true

        self._created_at.value = Time.now
        self._updated_at.value = Time.now
        if valid?
          LuckyRecord::Repo.run do |db|
            db.exec insert_sql.statement, insert_sql.args
          end
          true
        else
          false
        end
      end

      private def insert_sql
        LuckyRecord::Insert.new(@@table_name, changes)
      end

      def self.new_insert(params)
        new(params)
      end

      def self.new_insert(**params)
        params_with_stringified_keys = {} of String => String
        params.each do |key, value|
          params_with_stringified_keys[key.to_s] = value
        end

        new(params_with_stringified_keys)
      end

      def self.new_update(to record, with params)
        new(record, params)
      end

      {% for field in FIELDS %}
        @_{{field[:name].id}} : LuckyRecord::Field({{LuckyRecord::Types::TYPE_MAPPINGS[field[:type]]}}?)?

        def _{{field[:name].id}}
          @_{{field[:name].id}} ||= LuckyRecord::Field({{LuckyRecord::Types::TYPE_MAPPINGS[field[:type]]}}?).new(:{{field[:name].id}}, allowed_params["{{field[:name].id}}"]?, @record.try(&.{{field[:name].id}}))
        end

        def allowed_params
          @params.select(@@allowed_param_keys)
        end

        def set_{{field[:name].id}}_from_param(value)
          cast_result = {{ field[:type].id }}.parse_string(value)
          if cast_result.is_a? LuckyRecord::Type::SuccessfulCast
            _{{field[:name].id}}.value = cast_result.value
          else
            _{{field[:name].id}}.add_error "is invalid"
          end
        end
      {% end %}

      def fields
        [
          {% for field in FIELDS %}
            _{{field[:name].id}},
          {% end %}
        ]
      end
    end
  end

  macro setup_getters
    {% for field in FIELDS %}
      def {{field[:name].id}}
        {{ field[:type].id }}.parse @{{field[:name].id}}
      end
    {% end %}
  end

  macro field(name)
    field {{name}}, String
  end

  macro field(name, type, nilable = false)
    {% type = type.resolve %}
    {% if type == String %}
      {% type = LuckyRecord::StringType %}
    {% end %}
    {% if type == Time %}
      {% type = LuckyRecord::TimeType %}
    {% end %}
    {% if type == Int32 %}
      {% type = LuckyRecord::Int32Type %}
    {% end %}
    {% FIELDS << {name: name, type: type, nilable: nilable} %}
  end
end
