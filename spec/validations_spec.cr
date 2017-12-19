require "./spec_helper"

private class CallableMessage
  include LuckyRecord::CallableErrorMessage

  def initialize(@name = "")
  end

  def call(name, value)
    "#{@name} says: #{name} of '#{value}' is invalid"
  end
end

private class TestValidationUser
  include LuckyRecord::Validations
  @_age : LuckyRecord::Field(Int32?)?
  @_name : LuckyRecord::Field(String)?
  @_city : LuckyRecord::Field(String)?
  @_state : LuckyRecord::Field(String)?
  @_name_confirmation : LuckyRecord::Field(String)?
  @_terms : LuckyRecord::Field(Bool?)?

  @name : String
  @name_confirmation : String
  @city : String
  @state : String
  @age : Int32?
  @terms : Bool?

  def initialize(@name = "", @name_confirmation = "", @age = nil, @terms = false, @city = "", @state = "")
  end

  def validate
    validate_required name, age
    validate_acceptance_of terms
    self
  end

  def run_validations_with_message
    validate_required city, state, message: "ugh"
    validate_inclusion_of state, in: ["CA, NY"], message: "that one's not allowed"
    validate_confirmation_of name, with: name_confirmation, message: "name confirmation must match"
  end

  def run_validations_with_message_callables
    validate_required city, state, message: ->(field_name : String, field_value : String) { "#{field_name} required message from Proc" }
    validate_inclusion_of state, in: ["CA, NY"], message: CallableMessage.new(@name)
  end

  def run_confirmation_validations
    validate_confirmation_of name, with: name_confirmation
  end

  def run_inclusion_validations
    validate_inclusion_of name, in: ["Paul", "Pablo"]
  end

  macro field(type, name)
    def {{ name }}
      @_{{ name }} ||= LuckyRecord::Field({{ type }}).new(:{{ name }}, param: "", value: @{{ name }}, form_name: "blank")
    end
  end

  field String, name
  field String, name_confirmation
  field String, city
  field String, state
  field Int32?, age
  field Bool?, terms
end

describe LuckyRecord::Validations do
  describe "validate_required" do
    it "validates multiple fields" do
      validate(name: "", age: nil) do |user|
        user.name.errors.should eq ["is required"]
        user.age.errors.should eq ["is required"]
      end
    end

    it "adds no errors if things are present" do
      validate(name: "Paul") do |user|
        user.name.errors.empty?.should be_true
      end
    end
  end

  describe "validates with custom messages" do
    it "validates custom message for validates_required" do
      validate(city: "", state: "") do |user|
        user.run_validations_with_message
        user.city.errors.should contain "ugh"
        user.state.errors.should contain "ugh"
      end
    end

    it "validates custom message for validate_inclusion_of" do
      validate(state: "") do |user|
        user.run_validations_with_message
        user.state.errors.should contain "that one's not allowed"
      end
    end

    it "validates custom message for validate_inclusion_of" do
      validate(name: "Paul") do |user|
        user.run_validations_with_message
        user.name.errors.empty?.should be_true
        user.name_confirmation.errors.should contain "name confirmation must match"
      end
    end

    it "validates custom messages from callables" do
      validate(name: "Paul", city: "", state: "") do |user|
        user.run_validations_with_message_callables
        user.city.errors.should contain "city required message from Proc"
        user.state.errors.should contain "state required message from Proc"
        user.state.errors.should contain "Paul says: state of '' is invalid"
      end
    end
  end

  describe "validate_acceptance_of" do
    it "validates the field is true" do
      validate(terms: false) do |user|
        user.terms.errors.should eq ["must be accepted"]
      end

      validate(terms: true) do |user|
        user.terms.errors.empty?.should be_true
      end
    end
  end

  describe "validate_confirmation_of" do
    it "validates the fields match" do
      validate(name: "Paul", name_confirmation: "Pablo") do |user|
        user.run_confirmation_validations
        user.name_confirmation.errors.should eq ["must match"]
      end

      validate(name: "Paul", name_confirmation: "Paul") do |user|
        user.run_confirmation_validations
        user.name.errors.empty?.should be_true
      end
    end
  end

  describe "validate_inclusion_of" do
    it "validates" do
      validate(name: "Not Paul") do |user|
        user.run_inclusion_validations
        user.name.errors.should eq ["is invalid"]
      end

      validate(name: "Paul") do |user|
        user.run_inclusion_validations
        user.name.errors.empty?.should be_true
      end

      validate(name: "Pablo") do |user|
        user.run_inclusion_validations
        user.name.errors.empty?.should be_true
      end
    end
  end
end

private def validate(**args)
  user = TestValidationUser.new(**args)
  user = user.validate
  yield user
end
