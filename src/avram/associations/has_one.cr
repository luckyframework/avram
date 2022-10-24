module Avram::Associations::HasOne
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
      {% foreign_key = "#{@type.name.underscore.split("::").last.id}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    association \
      assoc_name: :{{ assoc_name.id }},
      type: {{ model }},
      foreign_key: :{{ foreign_key.id }},
      relationship_type: :has_one

    Avram::Associations.__define_public_preloaded_getters({{ assoc_name }}, {{ model }}, {{ nilable }})
    Avram::Associations.__define_preloaded_setter({{ assoc_name }}, {{ model }}, {{ nilable }})
    define_has_one_private_assoc_getter({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ nilable }})
    define_has_one_base_query({{ @type }}, {{ assoc_name }}, {{ model }}, {{ foreign_key }})
  end

  private macro define_has_one_private_assoc_getter(assoc_name, model, foreign_key, nilable)
    private def get_{{ assoc_name.id }}(allow_lazy : Bool = false) : {{ model }}{% if nilable %}?{% end %}
      if _{{ assoc_name }}_preloaded?
        @_preloaded_{{ assoc_name }}{% unless nilable %}.not_nil!{% end %}
      elsif lazy_load_enabled? || allow_lazy
        {{ model }}::BaseQuery.new
          .{{ foreign_key.id }}(id)
          .first{% if nilable %}?{% end %}
      else
        raise Avram::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
      end
    end
  end

  private macro define_has_one_base_query(class_type, assoc_name, model, foreign_key)
    class BaseQuery
      def self.preload_{{ assoc_name }}(record : {{ class_type }}, force : Bool = false) : {{ class_type }}
        preload_{{ assoc_name }}(record: record, preload_query: {{ model }}::BaseQuery.new, force: force)
      end

      def self.preload_{{ assoc_name }}(record : {{ class_type }}, force : Bool = false) : {{ class_type }}
        modified_query = yield {{ model }}::BaseQuery.new
        preload_{{ assoc_name }}(record: record, preload_query: modified_query, force: force)
      end

      def self.preload_{{ assoc_name }}(record : {{ class_type }}, preload_query : {{ model }}::BaseQuery, force : Bool = false) : {{ class_type }}
        return record if record._{{ assoc_name }}_preloaded? && !force

        new_record = record.dup
        assoc = preload_query.{{ foreign_key }}(record.id).first?
        new_record.__set_preloaded_{{ assoc_name }}(assoc)
        new_record
      end

      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), force : Bool = false) : Array({{ class_type }})
        preload_{{ assoc_name }}(records: records, preload_query: {{ model }}::BaseQuery.new, force: force)
      end

      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), force : Bool = false) : Array({{ class_type }})
        modified_query = yield {{ model }}::BaseQuery.new
        preload_{{ assoc_name }}(records: records, preload_query: modified_query, force: force)
      end

      def self.preload_{{ assoc_name }}(records : Enumerable({{ class_type }}), preload_query : {{ model }}::BaseQuery, force : Bool = false) : Array({{ class_type }})
        ids = records.compact_map do |record|
          if record._{{ assoc_name }}_preloaded? && !force
            nil
          else
            record.id
          end
        end
        empty_results = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
        {{ assoc_name }} = ids.empty? ? empty_results : preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
        records.map do |record|
          if record._{{ assoc_name }}_preloaded? && !force
            next record
          end

          record = record.dup
          assoc = {{ assoc_name }}[record.id]?.try(&.first?)
          record.tap(&.__set_preloaded_{{ assoc_name }}(assoc))
        end
      end

      def preload_{{ assoc_name }} : self
        preload_{{ assoc_name }}({{ model }}::BaseQuery.new)
      end

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
    end
  end
end
