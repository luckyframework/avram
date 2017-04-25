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
    setup_abstract_changeset_class({{table_name}})
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

  macro setup_abstract_changeset_class(table_name)
    abstract class BaseChangeset
      property? performed : Bool = false

      @record : {{@type}}?
      @params : Hash(String, String)
      @valid : Bool = true
      @errors = Hash(Symbol, Array(String)).new(Array(String).new)

      @@table_name = {{table_name}}

      def initialize(@params)
        extract_changes_from_params
      end

      private def extract_changes_from_params
        @params.each do |key, value|
          {% for field in FIELDS %}
            if key == {{field[:name].id.stringify}} && {{field[:name].id}}_allowed?
              self.{{field[:name].id}} = value
            end
          {% end %}
        end
      end

      def initialize(@record, @params)
      end

      def valid? : Bool
        call
        @valid
      end

      def call
        # TODO add default validate_required for non-nilable fields
      end

      macro allow(*field_names)
        \{% for field_name in field_names %}
          def \{{field_name.id}}_param
            super
          end

          def \{{field_name.id}}_allowed?
            true
          end

          def \{{field_name.id}}_field
            _\{{field_name.id}}_field
          end
        \{% end %}
      end

      def save : Bool
        @performed = true

        self.created_at = Time.now
        self.updated_at = Time.now
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

      def changes
        _changes = {} of Symbol => String?
        {% for field in FIELDS %}
          if {{field[:name].id}}_changed?
            _changes[:{{field[:name].id}}] = {{field[:name].id}}_as_db_string
          end
        {% end %}
        _changes
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
        getter? {{field[:name].id}}_changed : Bool = false
        @{{field[:name].id}} : {{LuckyRecord::Types::TYPE_MAPPINGS[field[:type]]}}?

        def {{field[:name].id}}_allowed?
          false
        end

        private def _{{field[:name].id}}_field
          LuckyRecord::Field({{LuckyRecord::Types::TYPE_MAPPINGS[field[:type]]}}?).new :{{field[:name].id}},
            {{field[:name].id}},
            {{field[:name].id}}_errors
        end

        def {{field[:name].id}}=(value)
          {{field[:name].id}}_changed!
          @{{field[:name].id}} = {{ field[:type].id }}.parse_string(value)
        end

        def {{field[:name].id}}_changed!
          @{{field[:name].id}}_changed = true
        end

        def {{field[:name].id}}_as_db_string
          {{ field[:type].id }}.to_db_string {{field[:name].id}}
        end

        def {{field[:name].id}}
          @{{field[:name].id}} ||
            {{ field[:type].id }}.parse_string({{field[:name].id}}_param) ||
            @record.try &.{{field[:name].id}}
        end

        private def {{field[:name].id}}_param
          @params["{{field[:name].id}}"]?
        end

        def add_{{field[:name].id}}_error(message)
          @valid = false
          @errors[:{{field[:name].id}}]
          @errors[:{{field[:name].id}}] = (@errors[:{{field[:name].id}}] + [message]).uniq
        end

        def {{field[:name].id}}_errors
          @errors[:{{field[:name].id}}]
        end
      {% end %}
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
