require "./spec_helper.cr"

describe "Avram::Attribute" do
  it "Attribute#value returns nil on empty strings" do
    empty_string = Avram::Attribute.new(name: :blank, param: nil, value: " ", param_key: "test_form")
    empty_string.value.should be_nil

    empty_array = Avram::Attribute.new(name: :empty_array, param: nil, value: [] of String, param_key: "test_form")
    empty_array.value.should_not be_nil
  end

  it "can reset errors" do
    attribute = Avram::Attribute.new(name: :blank, param: nil, value: " ", param_key: "na")
    attribute.add_error "an error"
    attribute.errors.empty?.should be_false

    attribute.reset_errors
    attribute.errors.empty?.should be_true
  end
end
