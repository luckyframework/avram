class CustomEmail
  def self.adapter
    Lucky
  end

  def initialize(@email : String)
  end

  def to_s
    value
  end

  private def value
    @email.strip.downcase
  end

  def blank?
    @email.blank?
  end

  module Lucky
    alias ColumnType = String
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, CustomEmail).new(query, column)
    end

    def parse(value : CustomEmail)
      SuccessfulCast(CustomEmail).new(value)
    end

    def parse(value : String)
      SuccessfulCast(CustomEmail).new(CustomEmail.new(value))
    end

    def to_db(value : String)
      CustomEmail.new(value).to_s
    end

    def to_db(value : CustomEmail)
      value.to_s
    end

    class Criteria(T, V) < String::Lucky::Criteria(T, V)
      @upper = false
      @lower = false
    end
  end
end
