macro redeclare_avram_enum(name)
  {% for member in name.resolve.constants %}
    {{ member }} = {{ name }}::{{ member }}
  {% end %}
end

macro avram_enum(enum_name, &block)
  {% avram_enum = ("Avram" + enum_name.names.join("::")).id %}
  enum {{ avram_enum }}
    {{ block.body }}

    def ===(other : Int32)
      value == other
    end
  end

  struct {{ enum_name }}
    def self.adapter
      Lucky
    end

    redeclare_avram_enum({{ avram_enum }})

    getter :enum

    # You may need to prefix with {{ @type }}
    #
    #   {{ @type }}::{{enum_name}}
    def initialize(@enum : Avram{{ enum_name }})
    end

    def initialize(enum_value : Int32)
      @enum = Avram{{ enum_name }}.from_value(enum_value)
    end

    def initialize(enum_value : String)
      int_value = enum_value.to_i?
      @enum = if int_value
                Avram{{ enum_name }}.from_value(int_value)
              else
                Avram{{ enum_name }}.parse(enum_value)
              end
    end

    delegate :===, to_s, to_i, to: @enum

    forward_missing_to @enum

    module Lucky
      alias ColumnType = Int32
      include Avram::Type

      def self.criteria(query : T, column) forall T
        Criteria(T, Int32).new(query, column)
      end

      def from_db!(value : Int32)
        {{ enum_name }}.new(value)
      end

      def parse(value : Avram{{ enum_name }})
        SuccessfulCast({{ enum_name }}).new(value)
      end

      def parse(value : String)
        SuccessfulCast({{ enum_name }}).new({{ enum_name }}.new(value))
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
