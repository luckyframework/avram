macro avram_enum(enum_name, &block)
  enum Avram{{ enum_name }}
    {{ block.body }}
  end

  class {{ enum_name }}
    def self.adapter
      Lucky
    end

    # You may need to prefix with {{ @type }}
    #
    #   {{ @type }}::{{enum_name}}
    def initialize(@enum : Avram{{ enum_name }})
    end

    def initialize(enum_value : Int32)
      @enum = Avram{{ enum_name }}.from_value(enum_value)
    end

    def initialize(enum_value : String)
      @enum = Avram{{ enum_name }}.from_value(enum_value.to_i)
    end

    forward_missing_to @enum

    module Lucky
      alias ColumnType = Int32
      include Avram::Type

      def from_db!(value : Int32)
        {{ enum_name }}.new(value)
      end

      def parse(value : Avram{{ enum_name }})
        SuccessfulCast({{ enum_name }}).new(value)
      end

      def parse(value : String)
        SuccessfulCast({{ enum_name }}).new({{ enum_name }}.new(value.to_i))
      end

      def parse(value : Int32)
        SuccessfulCast({{ enum_name }}).new({{ enum_name }}.new(value))
      end

      def to_db(value : Int32)
        value.to_s
      end

      def to_db(value : {{ enum_name }})
        value.value.to_s
      end

      class Criteria(T, V) < Int32::Lucky::Criteria(T, V)
      end
    end
  end
end
