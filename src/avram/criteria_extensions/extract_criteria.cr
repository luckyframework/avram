module Avram
  enum ChronoUnits
    Century
    Day
    Decade
    Dow
    Doy
    Epoch
    Hour
    Isodow
    Isoyear
    Julian
    Microseconds
    Millennium
    Milliseconds
    Minute
    Month
    Quarter
    Second
    Timezone
    Timezone_hour
    Timezone_minute
    Week
    Year
  end
end

module Avram::ExtractCriteria
  macro included
    def extract(chrono_unit : Avram::ChronoUnits)
        applied_operation = "extract(#{chrono_unit.to_s.downcase} from #{@column})"
        case chrono_unit
        when .julian?, .second?, .milliseconds?, .epoch?
            Criteria(T,Float64).new(rows, applied_operation)
        else Criteria(T,Int32).new(rows, applied_operation)
        end
    end

    def extract(symbol : Symbol)
        extract(Avram::ChronoUnits.parse(symbol.to_s))
    end

    def extract_day
        extract(Avram::ChronoUnits::Day)
    end

    def extract_month
        extract(Avram::ChronoUnits::Month)
    end

    def extract_century
        extract(Avram::ChronoUnits::Century)
    end

    def extract_decade
        extract(Avram::ChronoUnits::Decade)
    end

    def extract_dow
        extract(Avram::ChronoUnits::Dow)
    end

    def extract_doy
        extract(Avram::ChronoUnits::Doy)
    end

    def extract_epoch
        extract(Avram::ChronoUnits::Epoch)
    end

    def extract_hour
        extract(Avram::ChronoUnits::Hour)
    end

    def extract_isodow
        extract(Avram::ChronoUnits::Isodow)
    end

    def extract_isoyear
        extract(Avram::ChronoUnits::Isoyear)
    end

    def extract_julian
        extract(Avram::ChronoUnits::Julian)
    end

    def extract_microseconds
        extract(Avram::ChronoUnits::Microseconds)
    end

    def extract_millennium
        extract(Avram::ChronoUnits::Millennium)
    end

    def extract_milliseconds
        extract(Avram::ChronoUnits::Milliseconds)
    end

    def extract_minute
        extract(Avram::ChronoUnits::Minute)
    end

    def extract_quarter
        extract(Avram::ChronoUnits::Quarter)
    end

    def extract_second
        extract(Avram::ChronoUnits::Second)
    end

    def extract_timezone
        extract(Avram::ChronoUnits::Timezone)
    end

    def extract_timezone_hour
        extract(Avram::ChronoUnits::Timezone_hour)
    end

    def extract_timezone_minute
        extract(Avram::ChronoUnits::Timezone_minute)
    end

    def extract_week
        extract(Avram::ChronoUnits::Week)
    end

    def extract_year
        extract(Avram::ChronoUnits::Year)
    end

end
end
