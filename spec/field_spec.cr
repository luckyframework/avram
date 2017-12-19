require "./spec_helper.cr"

describe "LuckyRecord::Field" do
  it "Field#value returns nil on empty strings" do
    empty_string = LuckyRecord::Field.new(name: :blank, param: nil, value: " ", form_name: "test_form")
    empty_string.value.should be_nil

    empty_array = LuckyRecord::Field.new(name: :empty_array, param: nil, value: [] of String, form_name: "test_form")
    empty_array.value.should_not be_nil
  end
end
