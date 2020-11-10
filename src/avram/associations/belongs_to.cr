module Avram::Associations::BelongsTo
  macro belongs_to(type_declaration, foreign_key = nil, table = nil)
    {% assoc_name = type_declaration.var %}

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    {% if !foreign_key %}
      {% foreign_key = "#{assoc_name}_id".id %}
    {% end %}

    {% if !table %}
      {% table = run("../../run_macros/infer_table_name.cr", model.id) %}
    {% end %}

    column {{ foreign_key.id }} : {{ model }}::PrimaryKeyType{% if nilable %}?{% end %}

    association \
      table_name: :{{ table.id }},
      type: {{ model }},
      foreign_key: :{{ foreign_key.id }},
      relationship_type: :belongs_to

    define_belongs_to_private_assoc_getter({{ assoc_name }}, {{ model }}, {{ foreign_key.id }}, {{ nilable }})
    Avram::Associations.__define_public_preloaded_getters({{ assoc_name }}, {{ model }}, {{ nilable }})
    Avram::Associations.__define_preloaded_setter({{ assoc_name }}, {{ model }})
    define_belongs_to_base_query({{ assoc_name }}, {{ model }}, {{ foreign_key.id }})
  end

  private macro define_belongs_to_private_assoc_getter(assoc_name, model, foreign_key, nilable)
    private def get_{{ assoc_name.id }}(allow_lazy : Bool = false) : {{ model }}{% if nilable %}?{% end %}
      if _{{ assoc_name }}_preloaded?
        @_preloaded_{{ assoc_name }}{% unless nilable %}.not_nil!{% end %}
      elsif lazy_load_enabled? || allow_lazy
        {{ foreign_key }}.try do |value|
          {{ model }}::BaseQuery.new.find(value)
        end
      else
        raise Avram::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
      end
    end
  end

  private macro define_belongs_to_base_query(assoc_name, model, foreign_key)
    class BaseQuery
      def preload_{{ assoc_name }}
        preload_{{ assoc_name }}({{ model }}::BaseQuery.new)
      end

      def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = [] of {{ model }}::PrimaryKeyType
          records.each do |record|
            record.{{ foreign_key }}.try do |id|
              ids << id
            end
          end
          empty_results = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
          {{ assoc_name }} = ids.empty? ? empty_results  : preload_query.dup.id.in(ids).results.group_by(&.id)
          records.each do |record|
            if (id = record.{{ foreign_key }})
              record.__set_preloaded_{{ assoc_name }} {{ assoc_name }}[id]?.try(&.first?)
            else
              record.__set_preloaded_{{ assoc_name }} nil
            end
          end
        end
        self
      end
    end
  end
end
