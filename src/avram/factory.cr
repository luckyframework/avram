class Avram::Factory
  macro register(klass, &block)
    {% operation = "#{klass.id}::SaveOperation".id %}

    class Avram::Private::{{klass}}Factory

      getter operation : {{ operation }} = {{ operation }}.new

      def self.create
        new.create {{ block }}
      end

      def create
        with self yield
        operation.save!
      end

      Avram::Factory.setup_instance_methods({{ operation }})
    end
  end

  macro setup_instance_methods(operation)
    {% for attribute in operation.resolve.constant(:COLUMN_ATTRIBUTES) %}
      def {{ attribute[:name] }}
        operation.{{ attribute[:name] }}.value = yield
      end
    {% end %}
  end

  macro create(klass)
    Avram::Private::{{klass}}Factory.create
  end
end
