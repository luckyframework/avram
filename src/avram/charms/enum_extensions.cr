macro avram_enum(enum_name, &block)
  enum Avram{{ enum_name }}
    {{ block.body }}
  end

  class {{ enum_name }}
    extend Avram::Type

    def self.parse_attribute(value : Avram{{ enum_name }})
      Avram::Type::SuccessfulCast({{ enum_name }}).new(value)
    end

    def self.parse_attribute(value : String)
      Avram::Type::SuccessfulCast({{ enum_name }}).new({{ enum_name }}.new(value.to_i))
    end

    def self.parse_attribute(value : Int32)
      Avram::Type::SuccessfulCast({{ enum_name }}).new({{ enum_name }}.new(value))
    end

    def self.from_rs(rs)
      rs.read(Int32?).try { |i| {{ enum_name }}.new(i) }
    end

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
      @enum = Avram{{ enum_name }}.from_value(enum_value.to_i)
    end

    forward_missing_to @enum

    def to_s
      @enum.value.to_s
    end

    module Lucky
      class Criteria(T, V) < Int32::Lucky::Criteria(T, V)
      end
    end
  end
end
