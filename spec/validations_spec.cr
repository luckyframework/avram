require "./spec_helper"

private class TestValidationUser
  include LuckyRecord::Validations
  @_age : LuckyRecord::Field(Int32?)?
  @_name : LuckyRecord::Field(String)?

  def initialize(@name : String, @age : Int32? = nil)
  end

  def run_validate_required
    validate_required name, age
  end

  def name
    @_name ||= LuckyRecord::Field(String).new(:name, param: "", value: @name)
  end

  def age
    @_age ||= LuckyRecord::Field(Int32?).new(:age, param: "", value: @age)
  end
end

describe LuckyRecord::Validations do
  describe "validate_required" do
    it "validates multiple fields" do
      test_validations(name: "", age: nil) do |user|
        user.run_validate_required
        user.name.errors.should eq ["is required"]
        user.age.errors.should eq ["is required"]
      end
    end

    it "adds no errors if things are present" do
      test_validations(name: "Paul") do |user|
        user.run_validate_required
        user.name.errors.empty?.should be_true
      end
    end
  end
end

private def test_validations(**args)
  user = TestValidationUser.new(**args)
  yield user
end
