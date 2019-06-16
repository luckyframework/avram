require "./spec_helper"

private class CallableMessage
  include Avram::CallableErrorMessage

  def initialize(@name = "")
  end

  def call(name, value)
    "#{@name} says: #{name} of '#{value}' is invalid"
  end
end

class UniquenessWithDatabaseBackedSaveOperation < User::SaveOperation
  permit_columns name

  def prepare
    validate_uniqueness_of name
    validate_uniqueness_of nickname, query: UserQuery.new.nickname.lower
  end
end

private class TestValidationUser
  include Avram::Validations
  @_age : Avram::Attribute(Int32?)?
  @_name : Avram::Attribute(String)?
  @_city : Avram::Attribute(String)?
  @_state : Avram::Attribute(String)?
  @_name_confirmation : Avram::Attribute(String)?
  @_terms : Avram::Attribute(Bool?)?

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

  def run_validate_required_when_value_is_false
    validate_required terms
  end

  def run_validations_with_message
    validate_required city, state, message: "ugh"
    validate_inclusion_of state, in: ["CA, NY"], message: "that one's not allowed"
    validate_confirmation_of name, with: name_confirmation, message: "name confirmation must match"
    validate_uniqueness_of name, query: UserQuery.new.name, message: "cannot be used"
  end

  def run_validations_with_message_callables
    validate_required city, state, message: ->(attribute_name : String, attribute_value : String) { "#{attribute_name} required message from Proc" }
    validate_inclusion_of state, in: ["CA, NY"], message: CallableMessage.new(@name)
  end

  def run_confirmation_validations
    validate_confirmation_of name, with: name_confirmation
  end

  def run_inclusion_validations
    validate_inclusion_of name, in: ["Paul", "Pablo"]
  end

  def run_exact_size_validation
    validate_size_of name, is: 2
  end

  def run_minimum_size_validation
    validate_size_of name, min: 2
  end

  def run_maximum_size_validation
    validate_size_of name, max: 4
  end

  def run_range_size_validation
    validate_size_of name, min: 2, max: 5
  end

  def run_impossible_size_validation
    validate_size_of name, min: 4, max: 1
  end

  macro column(type, name)
    def {{ name }}
      @_{{ name }} ||= Avram::Attribute({{ type }}).new(:{{ name }}, param: "", value: @{{ name }}, form_name: "blank")
    end
  end

  column String, name
  column String, name_confirmation
  column String, city
  column String, state
  column Int32?, age
  column Bool?, terms
end

describe Avram::Validations do
  describe "validate_required" do
    it "validates multiple attributes" do
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

    it "adds no error if the value is 'false'" do
      validate(terms: false) do |user|
        user.terms.reset_errors
        user.run_validate_required_when_value_is_false
        user.terms.errors.empty?.should be_true
      end

      validate(terms: nil) do |user|
        user.terms.reset_errors
        user.run_validate_required_when_value_is_false
        user.terms.errors.should contain "is required"
      end
    end
  end

  describe "validate_uniqueness_of" do
    it "validates that a new record is unique with a query or without one" do
      existing_user = UserBox.new.name("Sally").nickname("Sal").create
      form = UniquenessWithDatabaseBackedSaveOperation.new
      form.name.value = existing_user.name
      form.nickname.value = existing_user.nickname.not_nil!.downcase

      form.prepare

      form.name.errors.should contain "is already taken"
      form.nickname.errors.should contain "is already taken"
    end

    it "ignores the existing record on update" do
      existing_user = UserBox.new.name("Sally").create
      form = UniquenessWithDatabaseBackedSaveOperation.new(existing_user)
      form.name.value = existing_user.name

      form.prepare

      form.name.errors.should_not contain "is already taken"
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

    it "validates custom message for validate_uniqueness_of" do
      existing_user = UserBox.create
      validate(name: existing_user.name) do |user|
        user.run_validations_with_message
        user.name.errors.should contain "cannot be used"
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
    it "validates the attribute value is true" do
      validate(terms: false) do |user|
        user.terms.errors.should eq ["must be accepted"]
      end

      validate(terms: nil) do |user|
        user.terms.errors.should eq ["must be accepted"]
      end

      validate(terms: true) do |user|
        user.terms.errors.empty?.should be_true
      end
    end
  end

  describe "validate_confirmation_of" do
    it "validates the attribute values match" do
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

  describe "validate_size_of" do
    it "validates" do
      validate(name: "P") do |user|
        user.run_exact_size_validation
        user.name.errors.should eq ["is invalid"]
      end

      validate(name: "P") do |user|
        user.run_minimum_size_validation
        user.name.errors.should eq ["is too short"]
      end

      validate(name: "Pablo") do |user|
        user.run_maximum_size_validation
        user.name.errors.should eq ["is too long"]
      end

      validate(name: "Paul") do |user|
        user.run_range_size_validation
        user.name.errors.should eq [] of String
      end
    end

    it "raises an error for an impossible condition" do
      validate(name: "Paul") do |user|
        expect_raises(Avram::ImpossibleValidation) do
          user.run_impossible_size_validation
        end
      end
    end
  end
end

private def validate(**args)
  user = TestValidationUser.new(**args)
  user = user.validate
  yield user
end
