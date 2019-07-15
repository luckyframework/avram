module Avram::Associations::HasMany
  macro has_many(type_declaration, through = nil, foreign_key = nil, polymorphic = false)
    {% if !through.is_a?(NilLiteral) && !through.is_a?(SymbolLiteral) %}
      {% through.raise "The association name for 'through' must be a Symbol. Instead, got: #{through}" %}
    {% end %}
    {% assoc_name = type_declaration.var %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    {% if polymorphic != false %}
      {% foreign_key = polymorphic.id + "_id" %}
    {% end %}

    association \
      table_name: :{{ assoc_name }},
      type: {{ type_declaration.type }},
      foreign_key: :{{ foreign_key }},
      through: {{ through }},
      relationship_type: :has_many

    {% model = type_declaration.type %}

    define_has_many_lazy_loading({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }}, {{ polymorphic }})
    define_has_many_base_query({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{through}}, {{ polymorphic }})
  end

  private macro define_has_many_base_query(assoc_name, model, foreign_key, through, polymorphic)
    class BaseQuery < Avram::Query
      def preload_{{ assoc_name }}
        preload_{{ assoc_name }}({{ model }}::BaseQuery.new)
      end

      def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = records.map(&.id)
          {% if through %}
            all_{{ assoc_name }} = preload_query
              .dup
              .join_{{ through.id }}
              .where_{{ through.id }} do |through_query|
                through_query.{{ foreign_key.id }}.in(ids)
              end
              .preload_{{ through.id }}
              .distinct

            {{ assoc_name }} = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
            all_{{ assoc_name }}.each do |item|
              item.{{ through.id }}.each do |item_through|
                {{ assoc_name }}[item_through.{{ foreign_key }}] ||= Array({{ model }}).new
                {{ assoc_name }}[item_through.{{ foreign_key }}] << item
              end
            end
          {% elsif polymorphic %}
            klass = self.class.name.gsub(/::BaseQuery$/, "")
            klass = klass.gsub(/Query$/, "")
            {{ assoc_name }} = preload_query
              .dup
              .{{ polymorphic.id }}_type(klass)
              .{{ polymorphic.id }}_id.in(ids)
              .results.group_by(&.{{ foreign_key }})
          {% else %}
            {{ assoc_name }} = preload_query
              .dup
              .{{ foreign_key }}.in(ids)
              .results.group_by(&.{{ foreign_key }})
          {% end %}
          records.each do |record|
            record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.id]? || [] of {{ model }}
          end
        end
        self
      end
    end
  end

  private macro define_has_many_lazy_loading(assoc_name, model, foreign_key, through, polymorphic)
    @_preloaded_{{ assoc_name }} : Array({{ model }})?
    setter _preloaded_{{ assoc_name }}

    def {{ assoc_name.id }} : Array({{ model }})
      @_preloaded_{{ assoc_name }} \
      || maybe_lazy_load_{{ assoc_name }} \
      || raise Avram::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
    end

    def {{ assoc_name.id }}! : Array({{ model }})
      @_preloaded_{{ assoc_name }} || lazy_load_{{ assoc_name }}
    end

    private def maybe_lazy_load_{{ assoc_name }}  : Array({{ model }})?
      if lazy_load_enabled?
        lazy_load_{{ assoc_name }}
      end
    end

    private def lazy_load_{{ assoc_name }} : Array({{ model }})
      {% if through %}
        {{ model }}::BaseQuery
          .new
          .join_{{ through.id }}
          .where_{{ through.id }} do |through_query|
            through_query.{{ foreign_key.id }}(id)
          end
          .preload_{{ through.id }}
          .results
      {% elsif polymorphic %}
        {{ model }}::BaseQuery
          .new
          .{{ polymorphic.id }}_type(self.class.name)
          .{{ foreign_key }}(id)
          .results
      {% else %}
        {{ model }}::BaseQuery
          .new
          .{{ foreign_key }}(id)
          .results
      {% end %}
    end
  end
end
