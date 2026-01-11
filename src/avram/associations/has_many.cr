module Avram::Associations::HasMany
  macro has_many(type_declaration, foreign_key = nil, through = nil, base_query_class = nil)
    {% if !through.is_a?(NilLiteral) && (!through.is_a?(ArrayLiteral) || through.any? { |item| !item.is_a?(SymbolLiteral) }) %}
      {% through.raise <<-ERROR
      'through' on #{@type.name} must be given an Array(Symbol). Instead, got: #{through}

      Example...
         has_many comments : Comment
         has_many related_authors : User, through: [:comments, :author]

      Learn more about associations: https://luckyframework.org/guides/database/models#model-associations
      ERROR
      %}
    {% end %}
    {% if !through.is_a?(NilLiteral) && through.size < 2 %}
      {% through.raise <<-ERROR
      'through' on #{@type.name} must be given at least two items. Instead, got: #{through}

      Example...
         has_many comments : Comment
         has_many related_authors : User, through: [:comments, :author]

      Learn more about associations: https://luckyframework.org/guides/database/models#model-associations
      ERROR
      %}
    {% end %}
    {% assoc_name = type_declaration.var %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore.split("::").last.id}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}
    {% model = type_declaration.type %}
    {% query_class = base_query_class || "#{model}::BaseQuery".id %}

    association \
      assoc_name: :{{ assoc_name }},
      type: {{ type_declaration.type }},
      foreign_key: :{{ foreign_key }},
      through: {{ through }},
      relationship_type: :has_many,
      base_query_class: {{ query_class }}

    define_has_many_lazy_loading({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }})
    define_has_many_base_query({{ @type }}, {{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }}, {{ query_class }})
  end

  private macro define_has_many_base_query(class_type, assoc_name, model, foreign_key, through, query_class)
    class BaseQuery
      def self.preload_{{ assoc_name }}(record : {{ class_type }}, force : Bool = false) : {{ class_type }}
        preload_{{ assoc_name }}(record: record, preload_query: {{ query_class }}.new, force: force)
      end

      def self.preload_{{ assoc_name }}(record : {{ class_type }}, force : Bool = false) : {{ class_type }}
        modified_query = yield {{ query_class }}.new
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
        new_record._preloaded_{{ assoc_name }} = preload_query.{{ foreign_key }}(record.id).results
        new_record
      end
      {% end %}

      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), force : Bool = false) : Array({{ class_type }})
        preload_{{ assoc_name }}(records: records, preload_query: {{ query_class }}.new, force: force)
      end

      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), force : Bool = false) : Array({{ class_type }})
        modified_query = yield {{ query_class }}.new
        preload_{{ assoc_name }}(records: records, preload_query: modified_query, force: force)
      end

      {% if through %}
      # force is an accepted argument, but is ignored
      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), preload_query : {{ model }}::BaseQuery, force : Bool = false) : Array({{ class_type }})
        intermediary_records = preload_{{ through.first.id }}(records, force: true) do |through_query|
          through_query.preload_{{ through[1].id }}(preload_query)
        end
        intermediary_records.map(&.dup)
          .map do |record|
            throughs = record.{{ through.first.id }}
            throughs = throughs.is_a?(Array) ? throughs : [throughs]
            record._preloaded_{{ assoc_name }} = throughs.compact.flat_map do |through|
              throughs1 = through.{{ through[1].id }}
              throughs1.is_a?(Array) ? throughs1 : [throughs1]
            end.compact

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
        {{ assoc_name }} = ids.empty? ? empty_results  : preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
        records.map do |record|
            if record.{{ assoc_name }}_preloaded? && !force
              next record
            end

            record = record.dup
            record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.id]? || [] of {{ model }}
            record
          end
      end
      {% end %}

      {% if through %}
      def preload_{{ assoc_name }}(*, through : Avram::Queryable? = nil) : self
        preload_{{ assoc_name }}({{ query_class }}.new, through: through)
      end
      {% else %}
      def preload_{{ assoc_name }} : self
        preload_{{ assoc_name }}({{ query_class }}.new)
      end
      {% end %}

      {% if through %}
      def preload_{{ assoc_name }}(*, through : Avram::Queryable? = nil, &) : self
        modified_query = yield {{ query_class }}.new
        preload_{{ assoc_name }}(modified_query, through: through)
      end
      {% else %}
      def preload_{{ assoc_name }}(&) : self
        modified_query = yield {{ query_class }}.new
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
              throughs = record.{{ through.first.id }}
              throughs = throughs.is_a?(Array) ? throughs : [throughs]
              record._preloaded_{{ assoc_name }} = throughs.compact.flat_map do |through|
                throughs1 = through.{{ through[1].id }}
                throughs1.is_a?(Array) ? throughs1 : [throughs1]
              end.compact
            end
          end
          self
        end
      {% else %}
        def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery) : self
          add_preload do |records|
            ids = records.map(&.id)
            if ids.empty?
              {{ assoc_name }} = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
            else
              {{ assoc_name }} = preload_query
                .{{ foreign_key }}.in(ids)
                .results.group_by(&.{{ foreign_key }})
            end
            records.each do |record|
              record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.id]? || [] of {{ model }}
            end
          end
          self
        end
      {% end %}
    end
  end

  private macro define_has_many_lazy_loading(assoc_name, model, foreign_key, through)
    @[DB::Field(ignore: true)]
    @_preloaded_{{ assoc_name }} : Array({{ model }})?
    @[DB::Field(ignore: true)]
    getter? {{ assoc_name }}_preloaded : Bool = false

    def _preloaded_{{ assoc_name }}=(vals : Array({{ model }})) : Array({{ model }})
      @{{ assoc_name }}_preloaded = true
      @_preloaded_{{ assoc_name }} = vals
    end

    def {{ assoc_name.id }} : Array({{ model }})
      @_preloaded_{{ assoc_name }} \
      || maybe_lazy_load_{{ assoc_name }} \
      || raise Avram::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
    end

    def {{ assoc_name.id }}! : Array({{ model }})
      @_preloaded_{{ assoc_name }} || lazy_load_{{ assoc_name }}
    end

    def {{ assoc_name.id }}_count : Int64
      {% if through %}
        {{ through.first.id }}_query
          .map(&.{{ through[1].id }}_count)
          .sum
      {% else %}
      {{ assoc_name.id }}_query.select_count
      {% end %}
    end

    private def maybe_lazy_load_{{ assoc_name }}  : Array({{ model }})?
      if lazy_load_enabled?
        lazy_load_{{ assoc_name }}
      end
    end

    private def lazy_load_{{ assoc_name }} : Array({{ model }})
      {% if through %}
        through_results = {{ through.first.id }}_query.preload_{{ through[1].id }}.results
        through_results = through_results.is_a?(Array) ? through_results : [through_results]
        through_results.compact.flat_map do |through_result|
          assoc_results = through_result.{{ through[1].id }}
          assoc_results.is_a?(Array) ? assoc_results : [assoc_results]
        end.compact
      {% else %}
        {{ assoc_name.id }}_query.results
      {% end %}
    end
  end
end
