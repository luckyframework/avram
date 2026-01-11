module Avram::Associations::HasOne
  macro has_one(type_declaration, foreign_key = nil, through = nil)
    {% if !through.is_a?(NilLiteral) && (!through.is_a?(ArrayLiteral) || through.any? { |item| !item.is_a?(SymbolLiteral) }) %}
      {% through.raise <<-ERROR
      'through' on #{@type.name} must be given an Array(Symbol). Instead, got: #{through}

      Example...
         has_one profile : Profile
         has_one avatar : Avatar, through: [:profile, :avatar]

      Learn more about associations: https://luckyframework.org/guides/database/models#model-associations
      ERROR
      %}
    {% end %}
    {% if !through.is_a?(NilLiteral) && through.size < 2 %}
      {% through.raise <<-ERROR
      'through' on #{@type.name} must be given at least two items. Instead, got: #{through}

      Example...
         has_one profile : Profile
         has_one avatar : Avatar, through: [:profile, :avatar]

      Learn more about associations: https://luckyframework.org/guides/database/models#model-associations
      ERROR
      %}
    {% end %}
    {% assoc_name = type_declaration.var %}

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore.split("::").last.id}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    association \
      assoc_name: :{{ assoc_name.id }},
      type: {{ model }},
      foreign_key: :{{ foreign_key.id }},
      through: {{ through }},
      relationship_type: :has_one

    Avram::Associations.__define_public_preloaded_getters({{ assoc_name }}, {{ model }}, {{ nilable }})
    Avram::Associations.__define_preloaded_setter({{ assoc_name }}, {{ model }}, {{ nilable }})
    define_has_one_private_assoc_getter({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ nilable }}, {{ through }})
    define_has_one_base_query({{ @type }}, {{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }})
  end

  private macro define_has_one_private_assoc_getter(assoc_name, model, foreign_key, nilable, through)
    private def get_{{ assoc_name.id }}(allow_lazy : Bool = false) : {{ model }}{% if nilable %}?{% end %}
      if {{ assoc_name }}_preloaded?
        @_preloaded_{{ assoc_name }}{% unless nilable %}.not_nil!{% end %}
      elsif lazy_load_enabled? || allow_lazy
        {% if through %}
          through_result = {{ through.first.id }}!
          if through_result
            result = through_result.{{ through[1].id }}
            result.is_a?(Array) ? result.first? : result
          else
            nil
          end{% unless nilable %}.not_nil!{% end %}
        {% else %}
          {{ model }}::BaseQuery.new
            .{{ foreign_key.id }}(id)
            .first{% if nilable %}?{% end %}
        {% end %}
      else
        raise Avram::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
      end
    end
  end

  private macro define_has_one_base_query(class_type, assoc_name, model, foreign_key, through)
    class BaseQuery
      def self.preload_{{ assoc_name }}(record : {{ class_type }}, force : Bool = false) : {{ class_type }}
        preload_{{ assoc_name }}(record: record, preload_query: {{ model }}::BaseQuery.new, force: force)
      end

      def self.preload_{{ assoc_name }}(record : {{ class_type }}, force : Bool = false) : {{ class_type }}
        modified_query = yield {{ model }}::BaseQuery.new
        preload_{{ assoc_name }}(record: record, preload_query: modified_query, force: force)
      end

      {% if through %}
      def self.preload_{{ assoc_name }}(record : {{ class_type }}, preload_query : {{ model }}::BaseQuery, force : Bool = false) : {{ class_type }}
        return record if record.{{ assoc_name }}_preloaded? && !force

        preload_{{ assoc_name }}(records: [record], preload_query: preload_query, force: force).first
      end
      {% else %}
      def self.preload_{{ assoc_name }}(record : {{ class_type }}, preload_query : {{ model }}::BaseQuery, force : Bool = false) : {{ class_type }}
        return record if record.{{ assoc_name }}_preloaded? && !force

        new_record = record.dup
        assoc = preload_query.{{ foreign_key }}(record.id).first?
        new_record.__set_preloaded_{{ assoc_name }}(assoc)
        new_record
      end
      {% end %}

      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), force : Bool = false) : Array({{ class_type }})
        preload_{{ assoc_name }}(records: records, preload_query: {{ model }}::BaseQuery.new, force: force)
      end

      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), force : Bool = false) : Array({{ class_type }})
        modified_query = yield {{ model }}::BaseQuery.new
        preload_{{ assoc_name }}(records: records, preload_query: modified_query, force: force)
      end

      {% if through %}
      # force is an accepted argument, but is ignored for through associations
      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), preload_query : {{ model }}::BaseQuery, force : Bool = false) : Array({{ class_type }})
        intermediary_records = preload_{{ through.first.id }}(records, force: true) do |through_query|
          through_query.preload_{{ through[1].id }}(preload_query)
        end
        intermediary_records.map(&.dup)
          .map do |record|
            through_record = record.{{ through.first.id }}
            if through_record
              assoc_result = through_record.{{ through[1].id }}
              # Handle both array and single results from the through association
              assoc = assoc_result.is_a?(Array) ? assoc_result.first? : assoc_result
              record.__set_preloaded_{{ assoc_name }}(assoc)
            else
              record.__set_preloaded_{{ assoc_name }}(nil)
            end
            record
          end
      end
      {% else %}
      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), preload_query : {{ model }}::BaseQuery, force : Bool = false) : Array({{ class_type }})
        ids = records.compact_map do |record|
          if record.{{ assoc_name }}_preloaded? && !force
            nil
          else
            record.id
          end
        end
        empty_results = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
        {{ assoc_name }} = ids.empty? ? empty_results : preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
        records.map do |record|
          if record.{{ assoc_name }}_preloaded? && !force
            next record
          end

          record = record.dup
          assoc = {{ assoc_name }}[record.id]?.try(&.first?)
          record.tap(&.__set_preloaded_{{ assoc_name }}(assoc))
        end
      end
      {% end %}

      {% if through %}
      def preload_{{ assoc_name }}(*, through : Avram::Queryable? = nil) : self
        preload_{{ assoc_name }}({{ model }}::BaseQuery.new, through: through)
      end
      {% else %}
      def preload_{{ assoc_name }} : self
        preload_{{ assoc_name }}({{ model }}::BaseQuery.new)
      end
      {% end %}

      {% if through %}
      def preload_{{ assoc_name }}(*, through : Avram::Queryable? = nil, &) : self
        modified_query = yield {{ model }}::BaseQuery.new
        preload_{{ assoc_name }}(modified_query, through: through)
      end
      {% else %}
      def preload_{{ assoc_name }}(&) : self
        modified_query = yield {{ model }}::BaseQuery.new
        preload_{{ assoc_name }}(modified_query)
      end
      {% end %}

      {% if through %}
      def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery, *, through : Avram::Queryable? = nil) : self
        preload_{{ through.first.id }} do |through_query|
          if base_q = through
            base_q.preload_{{ through[1].id }}(preload_query)
          else
            through_query.preload_{{ through[1].id }}(preload_query)
          end
        end
        add_preload do |records|
          records.each do |record|
            through_record = record.{{ through.first.id }}
            if through_record
              assoc_result = through_record.{{ through[1].id }}
              # Handle both array and single results from the through association
              assoc = assoc_result.is_a?(Array) ? assoc_result.first? : assoc_result
              record.__set_preloaded_{{ assoc_name }}(assoc)
            else
              record.__set_preloaded_{{ assoc_name }}(nil)
            end
          end
        end
        self
      end
      {% else %}
      def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery) : self
        add_preload do |records|
          ids = records.map(&.id)
          empty_results = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
          {{ assoc_name }} = ids.empty? ? empty_results : preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
          records.each do |record|
            record.__set_preloaded_{{ assoc_name }} {{ assoc_name }}[record.id]?.try(&.first?)
          end
        end
        self
      end
      {% end %}
    end
  end
end
