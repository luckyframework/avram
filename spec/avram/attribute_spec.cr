require "../spec_helper"

private class CallableMessage
  include Avram::CallableErrorMessage

  def call(attribute_name, attribute_value)
    "Error: #{attribute_name} with value of '#{attribute_value}' is invalid"
  end
end

private struct AttributeI18nBackend < Avram::I18nBackend
  def get(key : String | Symbol) : String
    case key
    when :validate_format_of
      "has an invalid format"
    else
      raise "Unexpected translation key: #{key}"
    end
  end
end

describe "Avram::Attribute" do
  describe "#add_error" do
    it "localizes default errors without changing explicitly supplied messages" do
      attribute = Avram::Attribute(String).new(name: :name, value: nil, param_key: "user")

      Avram.temp_config(i18n_backend: AttributeI18nBackend.new) do
        attribute.add_error
        attribute.add_error "is invalid"
      end

      attribute.errors.should eq(["has an invalid format", "is invalid"])
    end
  end

  describe "#extract" do
    it "localizes invalid scalar parameters" do
      attribute = Avram::Attribute(Int32).new(name: :age, value: nil, param_key: "user")

      Avram.temp_config(i18n_backend: AttributeI18nBackend.new) do
        attribute.extract(Avram::Params.new({"age" => "not-a-number"}))
      end

      attribute.errors.should eq(["has an invalid format"])
    end

    it "localizes invalid array parameters" do
      attribute = Avram::Attribute(Array(Int32)).new(name: :scores, value: nil, param_key: "user")

      Avram.temp_config(i18n_backend: AttributeI18nBackend.new) do
        attribute.extract(Avram::Params.new({"scores" => ["not-a-number"]}))
      end

      attribute.errors.should eq(["has an invalid format"])
    end

    it "localizes invalid upload parameters" do
      attribute = Avram::Attribute(Avram::Uploadable).new(name: :avatar, value: nil, param_key: "user")

      Avram.temp_config(i18n_backend: AttributeI18nBackend.new) do
        attribute.extract(Avram::Params.new({"avatar" => "not-an-upload"}))
      end

      attribute.errors.should eq(["has an invalid format"])
    end
  end

  describe "#value" do
    it "returns nil on empty strings" do
      empty_string = Avram::Attribute.new(name: :blank, param: nil, value: " ", param_key: "test_form")
      empty_string.value.should be_nil
    end

    it "does not return nil on empty arrays" do
      empty_array = Avram::Attribute.new(name: :empty_array, param: nil, value: [] of String, param_key: "test_form")
      empty_array.value.should_not be_nil
    end

    it "returns nil for empty uploads" do
      empty_upload = Avram::Attribute.new(name: :empty_upload, param: nil, value: Avram::UploadedFile.new(""), param_key: "test_form")
      empty_upload.value.should be_nil
    end
  end

  describe "#original_value" do
    it "returns nil on empty strings" do
      empty_string = Avram::Attribute.new(name: :blank, param: nil, value: " ", param_key: "test_form")
      empty_string.original_value.should be_nil
    end

    it "does not return nil on empty arrays" do
      empty_array = Avram::Attribute.new(name: :empty_array, param: nil, value: [] of String, param_key: "test_form")
      empty_array.original_value.should_not be_nil
    end

    it "returns nil for empty uploads" do
      empty_upload = Avram::Attribute.new(name: :empty_upload, param: nil, value: Avram::UploadedFile.new(""), param_key: "test_form")
      empty_upload.original_value.should be_nil
    end
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
    attribute.add_error ->(attribute_name : String, _attribute_value : String) { "#{attribute_name} message from Proc" }
    attribute.add_error CallableMessage.new

    attribute.errors.should eq([
      "attr_name message from Proc",
      "Error: attr_name with value of 'fake' is invalid",
    ])
  end

  describe "#changed?" do
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

    it "allows the from and to values to be nil" do
      attribute = Avram::Attribute(String).new(name: :color, param: nil, value: "teal", param_key: "test_form")
      attribute.value = nil
      attribute.changed?(to: nil).should be_true

      attribute = Avram::Attribute(String).new(name: :color, param: nil, value: nil, param_key: "test_form")
      attribute.value = "gold"
      attribute.changed?(from: nil).should be_true
    end

    it "treats a blank string as nil" do
      attribute = Avram::Attribute(String).new(name: :color, param: nil, value: " ", param_key: "test_form")
      attribute.value = "silver"
      attribute.changed?(from: nil).should be_true

      attribute = Avram::Attribute(String).new(name: :color, param: nil, value: "purple", param_key: "test_form")
      attribute.value = " "
      attribute.changed?(to: nil).should be_true
    end
  end
end
