require "./spec_helper"

private class TestValidationUser
  include LuckyRecord::Validations
  @_age : LuckyRecord::Field(Int32?)?
  @_name : LuckyRecord::Field(String)?
  @_name_confirmation : LuckyRecord::Field(String)?
  @_terms : LuckyRecord::Field(Bool)?

  @name : String
  @name_confirmation : String
  @age : Int32?
  @terms : Bool

  def initialize(@name = "", @name_confirmation = "", @age = nil, @terms = false)
  end

  def validate
    validate_required name, age
    validate_acceptance_of terms
    self
  end

  def run_confirmation_validations
    validate_confirmation_of name
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
  field Int32?, age
  field Bool, terms
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
        user.name.errors.should eq ["must match"]
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
