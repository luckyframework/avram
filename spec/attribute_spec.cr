require "./spec_helper.cr"

private class CallableMessage
  include Avram::CallableErrorMessage

  def call(name, value)
    "Error: #{name} with value of '#{value}' is invalid"
  end
end

describe "Avram::Attribute" do
  it "Attribute#value returns nil on empty strings" do
    empty_string = Avram::Attribute.new(name: :blank, param: nil, value: " ", param_key: "test_form")
    empty_string.value.should be_nil

    empty_array = Avram::Attribute.new(name: :empty_array, param: nil, value: [] of String, param_key: "test_form")
    empty_array.value.should_not be_nil
  end

  it "Attribute#original_value returns nil on empty strings" do
    empty_string = Avram::Attribute.new(name: :blank, param: nil, value: " ", param_key: "test_form")
    empty_string.original_value.should be_nil

    empty_array = Avram::Attribute.new(name: :empty_array, param: nil, value: [] of String, param_key: "test_form")
    empty_array.original_value.should_not be_nil
  end

  it "can reset errors" do
    attribute = Avram::Attribute.new(name: :blank, param: nil, value: " ", param_key: "na")
    attribute.add_error "an error"
    attribute.errors.empty?.should be_false

    attribute.reset_errors
    attribute.errors.empty?.should be_true
  end

  it "can accept custom callable messages" do
    attribute = Avram::Attribute.new(name: :attr_name, param: nil, value: "fake", param_key: "na")
    attribute.add_error ->(attribute_name : String, attribute_value : String) { "#{attribute_name} message from Proc" }
    attribute.add_error CallableMessage.new

    attribute.errors.should eq([
      "attr_name message from Proc",
      "Error: attr_name with value of 'fake' is invalid",
    ])
  end

  describe "Attribute#changed?" do
    it "tests if the value has changed since initialization" do
      attribute = Avram::Attribute.new(name: :state, param: nil, value: "caterpillar", param_key: "test_form")

      attribute.changed?.should be_false
      attribute.value = "caterpillar"
      attribute.changed?.should be_false
      attribute.value = "butterfly"
      attribute.changed?.should be_true
    end

    it "can detect change from and to a given value" do
      attribute = Avram::Attribute.new(name: :color, param: nil, value: "red", param_key: "test_form")

      attribute.value = "green"
      attribute.changed?(from: "blue").should be_false
      attribute.changed?(from: "red").should be_true
      attribute.changed?(to: "red").should be_false
      attribute.changed?(to: "green").should be_true
      attribute.changed?(from: "green", to: "blue").should be_false
      attribute.changed?(from: "red", to: "green").should be_true
    end

    it "treats an explicit nil as change" do
      attribute = Avram::Attribute.new(name: :color, param: nil, value: nil, param_key: "test_form")

      attribute.value = nil
      attribute.changed?.should be_true
    end
  end

  describe "Attribute#changes" do
    it "returns an array with changes of the value or nil" do
      attribute = Avram::Attribute.new(name: :color, param: nil, value: "pink", param_key: "test_form")

      attribute.changes.should be_nil
      attribute.value = "magenta"
      attribute.changes.should eq(["pink", "magenta"])
    end

    it "returns an array of nils if nil is set explicitly" do
      attribute = Avram::Attribute.new(name: :color, param: nil, value: nil, param_key: "test_form")

      attribute.value = nil
      attribute.changes.should eq([nil, nil])
    end
  end
end
