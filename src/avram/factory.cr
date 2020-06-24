class Avram::Factory
  macro register(klass)
    {% operation = "#{klass.id}::SaveOperation".id %}

    class Avram::Private::{{klass}}Factory
      getter property_setters = {} of String => Proc({{operation}}, Nil)
      getter association_setters = {} of String => Proc({{klass}}, Nil)
      getter traits : Array(Symbol)

      def initialize(@traits)
      end

      def create : {{ klass }}
        {{ yield }}
        with self yield
        operation = {{ operation }}.new
        property_setters.each { |k,v| v.call(operation) }
        model = operation.save!
        association_setters.each { |k,v| v.call(model) }
        model
      end

      def trait(name)
        if traits.includes?(name)
          with self yield
        end
      end

      Avram::Factory.setup_instance_methods({{ operation }})
      Avram::Factory.setup_association_methods({{ klass }})
    end
  end

  macro setup_instance_methods(operation)
    {% for attribute in operation.resolve.constant(:COLUMN_ATTRIBUTES) %}
      def {{ attribute[:name] }}(&block : Proc({{ attribute[:type] }}))
        property_setters["{{attribute[:name]}}"] = ->(op : {{ operation }}) { op.{{ attribute[:name] }}.value = block.call }
      end
    {% end %}
  end

  macro setup_association_methods(klass)
    {% for association in klass.resolve.constant(:ASSOCIATIONS) %}
      {% if association[:relationship_type] == :belongs_to %}
        {% name = association[:foreign_key].id.gsub(/_id/, "") %}
        def {{ name }}(&block : Proc({{ association[:type] }}))
          {{ association[:foreign_key].id }} do
            assoc = block.call
            association_setters["{{name}}"] = ->(model : {{ klass }}) { model.__set_preloaded_{{ name }}(assoc) }
            assoc.id
          end
        end

        def {{ name }}
          {{ name }} { Avram::Factory.create({{ association[:type] }}) }
        end
      {% end %}
    {% end %}
  end

  macro create(klass, *traits, &block)
    {% if traits.empty? %}
    passed_traits = [] of Symbol
    {% else %}
    passed_traits = [{{*traits}}]
    {% end %}
    factory = Avram::Private::{{klass}}Factory.new(passed_traits)
    factory.create {% if block %}{{block}}{% else %}{}{% end %}
  end
end
