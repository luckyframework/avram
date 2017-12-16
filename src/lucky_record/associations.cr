module LuckyRecord::Associations
  private def lazy_load_enabled?
    LuckyRecord::Repo.settings.lazy_load_enabled
  end

  macro has_many(type_declaration, foreign_key = nil)
    {% assoc_name = type_declaration.var %}

    association table_name: :{{ assoc_name }}

    {% model = type_declaration.type %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    @_preloaded_{{ assoc_name }} : Array({{ model }})?
    setter _preloaded_{{ assoc_name }}

    def {{ assoc_name.id }} : Array({{ model }})
      @_preloaded_{{ assoc_name }} \
      || lazy_load_{{ assoc_name }} \
      || raise LuckyRecord::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
    end

    private def lazy_load_{{ assoc_name }} : Array({{ model }})?
      if lazy_load_enabled?
        {{ model }}::BaseQuery.new.{{ foreign_key }}(id).results
      end
    end

    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}
        preload({{ model }}::BaseQuery.new)
      end

      def preload(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = records.map(&.id)
          {{ assoc_name }} = preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
          records.each do |record|
            record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.id]? || [] of {{ model }}
          end
        end
        self
      end
    end
  end

  macro has_one(type_declaration, foreign_key = nil)
    {% assoc_name = type_declaration.var %}

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    association table_name: :{{ model }}, foreign_key: {{ foreign_key }}

    @_{{ assoc_name }}_preloaded : Bool = false
    getter? _{{ assoc_name }}_preloaded
    getter _preloaded_{{ assoc_name }} : {{ model }}?

    def set_preloaded_{{ assoc_name }}(record : {{ model }}?)
      @_{{ assoc_name }}_preloaded = true
      @_preloaded_{{ assoc_name }} = record
    end

    def {{ assoc_name.id }} : {{ model }}{% if nilable %}?{% end %}
      if _{{ assoc_name }}_preloaded?
        @_preloaded_{{ assoc_name }}{% unless nilable %}.not_nil!{% end %}
      elsif lazy_load_enabled?
        query = {{ model }}::BaseQuery.new
        query.{{ foreign_key.id }}(id)

        query.first{% if nilable %}?{% end %}
      else
        raise LuckyRecord::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
      end
    end

    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}
        preload({{ model }}::BaseQuery.new)
      end

      def preload(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = records.map(&.id)
          {{ assoc_name }} = preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
          records.each do |record|
            record.set_preloaded_{{ assoc_name }} {{ assoc_name }}[record.id]?.try(&.first?)
          end
        end
        self
      end
    end
  end

  macro belongs_to(type_declaration)
    {% assoc_name = type_declaration.var %}
    {% foreign_key = "#{assoc_name}_id".id %}

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    column {{ assoc_name.id }}_id : Int32{% if nilable %}?{% end %}

    association table_name: :{{ model.resolve.constant(:TABLE_NAME).id }}, foreign_key: :id

    def {{ assoc_name.id }} : {{ model }}{% if nilable %}?{% end %}
      if _{{ assoc_name }}_preloaded?
        @_preloaded_{{ assoc_name }}{% unless nilable %}.not_nil!{% end %}
      elsif lazy_load_enabled?
        {{ foreign_key }}.try do |value|
          {{ model }}::BaseQuery.new.find(value)
        end
      else
        raise LuckyRecord::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
      end
    end

    @_{{ assoc_name }}_preloaded : Bool = false
    getter? _{{ assoc_name }}_preloaded
    getter _preloaded_{{ assoc_name }} : {{ model }}?

    def set_preloaded_{{ assoc_name }}(record : {{ model }}?)
      @_{{ assoc_name }}_preloaded = true
      @_preloaded_{{ assoc_name }} = record
    end

    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}
        preload({{ model }}::BaseQuery.new)
      end

      def preload(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = [] of Int32
          records.each do |record|
            record.{{ foreign_key }}.try do |id|
              ids << id
            end
          end
          {{ assoc_name }} = preload_query.id.in(ids).results.group_by(&.id)
          records.each do |record|
            if (id = record.{{ foreign_key }})
              record.set_preloaded_{{ assoc_name }} {{ assoc_name }}[id]?.try(&.first?)
            else
              record.set_preloaded_{{ assoc_name }} nil
            end
          end
        end
        self
      end
    end
  end
end
