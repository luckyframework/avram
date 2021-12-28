require "../spec_helper"

macro should_negate(original_where, expected_negated_where)
  {% if original_where.resolve < Avram::Where::NullSqlClause %}
    clause = {{original_where}}.new("column").negated
  {% else %}
    clause = {{original_where}}.new("column", "value").negated
  {% end %}
  clause.column.should eq "column"
  {% unless original_where.resolve < Avram::Where::NullSqlClause %}
    clause.value.should eq "value"
  {% end %}
  clause.should be_a({{expected_negated_where}})
end

describe Avram::Where do
  it "can be negated" do
    should_negate(Avram::Where::Equal, Avram::Where::NotEqual)
    should_negate(Avram::Where::NotEqual, Avram::Where::Equal)
    should_negate(Avram::Where::GreaterThan, Avram::Where::LessThanOrEqualTo)
    should_negate(Avram::Where::GreaterThanOrEqualTo, Avram::Where::LessThan)
    should_negate(Avram::Where::LessThan, Avram::Where::GreaterThanOrEqualTo)
    should_negate(Avram::Where::LessThanOrEqualTo, Avram::Where::GreaterThan)
    should_negate(Avram::Where::Like, Avram::Where::NotLike)
    should_negate(Avram::Where::NotLike, Avram::Where::Like)
    should_negate(Avram::Where::Ilike, Avram::Where::NotIlike)
    should_negate(Avram::Where::NotIlike, Avram::Where::Ilike)
    should_negate(Avram::Where::In, Avram::Where::NotIn)
    should_negate(Avram::Where::NotIn, Avram::Where::In)
    should_negate(Avram::Where::Null, Avram::Where::NotNull)
  end
end
