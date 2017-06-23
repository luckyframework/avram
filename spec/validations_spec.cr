require "./spec_helper"

private class TestValidationUser
  include LuckyRecord::Validations
  @_age : LuckyRecord::Field(Int32?)?
  @_name : LuckyRecord::Field(String)?
  @_terms : LuckyRecord::Field(Bool)?

  def initialize(@name : String = "", @age : Int32? = nil, @terms : Bool = false)
  end

  def validate
    validate_required name, age
    validate_acceptance_of terms
    self
  end

  def name
    @_name ||= LuckyRecord::Field(String).new(:name, param: "", value: @name)
  end

  def age
    @_age ||= LuckyRecord::Field(Int32?).new(:age, param: "", value: @age)
  end

  def terms
    @_terms ||= LuckyRecord::Field(Bool).new(:terms, param: "", value: @terms)
  end
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
end

private def validate(**args)
  user = TestValidationUser.new(**args)
  user = user.validate
  yield user
end
