require "../chrono_units"

module Avram::ExtractCriteria
  macro included

    {% chrono_units_as_names = Avram::ChronoUnits.constants.map(&.underscore) %}

    def extract(chrono_unit : Avram::ChronoUnits)
        chrono_unit_in_sql_format=chrono_unit.to_s.underscore
        applied_operation = "extract(#{chrono_unit_in_sql_format} from #{@column})"
        case chrono_unit
        when .julian?, .second?, .milliseconds?, .epoch?
            Criteria(T,Float64).new(rows, applied_operation)
        else Criteria(T,Int32).new(rows, applied_operation)
        end
    end

    def extract(symbol : Symbol)
        raise ArgumentError.new("Illegal value #{symbol} as a chrono unit. Allowed values are {{chrono_units_as_names}}") unless {{chrono_units_as_names.stringify}}.includes?(symbol.to_s)
        chrono_unit_enum_member = symbol.to_s.camelcase
        extract(Avram::ChronoUnits.parse(chrono_unit_enum_member))
    end

    {% for chrono_unit in chrono_units_as_names %}
        def extract_{{chrono_unit}}
            extract(:{{chrono_unit}})
        end
    {% end %}

  end
end
