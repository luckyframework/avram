require "./spec_helper.cr"

describe "Avram::Field" do
  it "Field#value returns nil on empty strings" do
    empty_string = Avram::Field.new(name: :blank, param: nil, value: " ", form_name: "test_form")
    empty_string.value.should be_nil

    empty_array = Avram::Field.new(name: :empty_array, param: nil, value: [] of String, form_name: "test_form")
    empty_array.value.should_not be_nil
  end

  it "can reset errors" do
    field = Avram::Field.new(name: :blank, param: nil, value: " ", form_name: "na")
    field.add_error "an error"
    field.errors.empty?.should be_false

    field.reset_errors
    field.errors.empty?.should be_true
  end
end
