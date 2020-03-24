macro avram_enum(enum_name, &block)
  enum {{ enum_name }}
    {{ block.body }}
  end

  class Avram{{ enum_name }}
    def self.adapter
      Lucky
    end

    # You may need to prefix with {{ @type }}
    #
    #   {{ @type }}::{{enum_name}}
    def initialize(@enum : {{ enum_name }})
    end

    def initialize(enum_value : Int32)
      @enum = {{ enum_name }}.from_value(enum_value)
    end

    def initialize(enum_value : String)
      @enum = {{ enum_name }}.from_value(enum_value.to_i)
    end

    def to_s
      @enum.to_s
    end

    def value
      @enum
    end

    def blank?
      @enum.nil?
    end

    module Lucky
      alias ColumnType = Int32
      include Avram::Type

      def from_db!(value : Int32)
        Avram{{ enum_name }}.new(value)
      end

      def parse(value : Avram{{ enum_name }})
        SuccessfulCast(Avram{{ enum_name }}).new(value)
      end

      def parse(value : String)
        SuccessfulCast(Avram{{ enum_name }}).new(Avram{{ enum_name }}.new(value.to_i))
      end

      def parse(value : Int32)
        SuccessfulCast(Avram{{ enum_name }}).new(Avram{{ enum_name }}.new(value))
      end

      def to_db(value : Int32)
        value.to_s
      end

      def to_db(value : Avram{{ enum_name }})
        value.value.value.to_s
      end

      class Criteria(T, V) < Int32::Lucky::Criteria(T, V)
      end
    end
  end
end
