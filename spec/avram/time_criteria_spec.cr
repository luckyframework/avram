require "../spec_helper"

private class QueryMe < BaseModel
  table users do
    column activated_at : Time
  end
end

describe Time::Lucky::Criteria do
  describe "is" do
    it "=" do
      now = Time.utc
      activated_at.eq(now).to_sql.should eq ["SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE users.activated_at = $1", now.to_s("%F %X.%6N %z")]
    end
  end

  it "as_date" do
    input_date = "2012-01-31"
    activated_at.as_date.eq(input_date).to_sql.should eq ["SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE DATE(users.activated_at) = $1", input_date]
  end

  describe "extract" do
    it "fails with non supported symbol" do
      expect_raises(ArgumentError) { activated_at.extract(:dayz).eq(5).to_sql }
    end

    describe "returning integer" do
      it "century" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(century from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Century).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:century).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_century.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "day" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(day from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Day).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:day).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_day.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "decade" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(decade from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Decade).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:decade).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_decade.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "dow" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(dow from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Dow).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:dow).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_dow.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "doy" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(doy from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Doy).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:doy).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_doy.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "hour" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(hour from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Hour).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:hour).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_hour.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "isodow" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(isodow from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Isodow).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:isodow).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_isodow.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "isoyear" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(isoyear from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Isoyear).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:isoyear).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_isoyear.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "microseconds" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(microseconds from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Microseconds).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:microseconds).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_microseconds.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "millennium" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(millennium from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Millennium).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:millennium).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_millennium.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "minute" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(minute from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Minute).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:minute).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_minute.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "month" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(month from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Month).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:month).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_month.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "quarter" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(quarter from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Quarter).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:quarter).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_quarter.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "timezone" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(timezone from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Timezone).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:timezone).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_timezone.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "timezone_hour" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(timezone_hour from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::TimezoneHour).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:timezone_hour).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_timezone_hour.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "timezone_minute" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(timezone_minute from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::TimezoneMinute).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:timezone_minute).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_timezone_minute.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "week" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(week from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Week).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:week).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_week.eq(5).to_sql.should eq [output_query, "5"]
      end

      it "year" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(year from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Year).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract(:year).eq(5).to_sql.should eq [output_query, "5"]
        activated_at.extract_year.eq(5).to_sql.should eq [output_query, "5"]
      end
    end

    describe "returning float" do
      it "epoch" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(epoch from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Epoch).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract(:epoch).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract_epoch.eq(5).to_sql.should eq [output_query, "5.0"]
      end

      it "julian" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(julian from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Julian).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract(:julian).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract_julian.eq(5).to_sql.should eq [output_query, "5.0"]
      end

      it "milliseconds" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(milliseconds from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Milliseconds).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract(:milliseconds).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract_milliseconds.eq(5).to_sql.should eq [output_query, "5.0"]
      end

      it "second" do
        output_query = "SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE extract(second from users.activated_at) = $1"
        activated_at.extract(Avram::ChronoUnits::Second).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract(:second).eq(5).to_sql.should eq [output_query, "5.0"]
        activated_at.extract_second.eq(5).to_sql.should eq [output_query, "5.0"]
      end
    end
  end
end

private def activated_at
  QueryMe::BaseQuery.new.activated_at
end
