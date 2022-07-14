require "../../spec_helper"

include ParamHelper

private class TestOperation < Avram::Operation
  attribute name : String
  attribute age : Int32

  def validate
    validate_required name
  end

  def run
    "Lucky Test"
  end
end

private class FailingTestOperation < Avram::Operation
  attribute name : String

  before_run do
    validate_required name
  end

  def run
    nil
  end
end

private class PassingTestOperation < Avram::Operation
  attribute name : String

  before_run do
    validate_required name
  end

  def run
    "run_method_called"
  end
end

private class TestOperationWithParamKey < Avram::Operation
  param_key :custom_key

  def run
    "Custom Key Test"
  end
end

private class TestOperationWithMultipleValidations < Avram::Operation
  param_key :multi
  attribute name : String
  attribute age : Int32

  def validate
    validate_required name
    validate_old_enough age
  end

  def run
    "Custom Key Test"
  end

  private def validate_old_enough(age_attribute)
    if (age = age_attribute.value) && age < 21
      age_attribute.add_error "is not old enough"
    end
  end
end

private class UserWithVirtual < User::SaveOperation
  attribute password : String
end

private class CanUseSameVirtualAttributeTwiceInModelBackedSaveOperation < User::SaveOperation
  attribute password : String
end

private class CanUseSameVirtualAttributeTwiceInOperation < Avram::Operation
  attribute name : String

  def run
  end
end

private class ParamKeySaveOperation < Avram::Operation
  param_key :custom_param

  def run
  end
end

describe Avram::Operation do
  describe "run" do
    it "returns the last statement from the run method" do
      TestOperation.run do |_operation, value|
        value.should eq "Lucky Test"
      end
    end

    it "has access to the raw params passed in" do
      params = build_params("custom_key:page=1&custom_key:per=50")
      TestOperationWithParamKey.run(params) do |operation, value|
        operation.params.should eq params
        operation.params.nested("custom_key").should eq({"page" => "1", "per" => "50"})
        value.should eq "Custom Key Test"
      end
    end

    it "is not called if operation invalid" do
      PassingTestOperation.run(name: "Foo") do |_, value|
        value.should eq("run_method_called")
      end

      PassingTestOperation.run do |_, value|
        value.should be_nil
      end
    end
  end

  describe "param_key" do
    it "has a param_key based on the name of the operation" do
      TestOperation.param_key.should eq "test_operation"
    end

    it "sets a custom param key with the param_key macro" do
      TestOperationWithParamKey.param_key.should eq "custom_key"
    end
  end

  describe "valid?" do
    it "returns true when there's nothing to validate" do
      TestOperation.run do |operation, _value|
        operation.valid?.should eq true
      end
    end
  end

  it "has create/update args for non column attributes" do
    UserWithVirtual.create(password: "p@ssword") do |operation, _user|
      operation.password.value = "p@ssword"
    end

    user = UserFactory.create
    UserWithVirtual.update(user, password: "p@ssword") do |operation, _user|
      operation.password.value = "p@ssword"
    end
  end

  it "sets a param_key based on the underscored class name" do
    TestOperation.param_key.should eq "test_operation"
  end

  it "allows overriding the param_key" do
    ParamKeySaveOperation.param_key.should eq "custom_param"
  end

  it "sets up initializers for params and no params" do
    operation = TestOperation.new
    operation.name.value.should be_nil
    operation.name.value = "Megan"
    operation.name.value.should eq("Megan")

    params = build_params("test_operation:name=Jordan")
    operation = TestOperation.new(params)
    operation.name.value.should eq("Jordan")
  end

  it "parses params" do
    params = build_params("test_operation:age=45")
    operation = TestOperation.new(params)
    operation.age.value.should eq 45
    operation.age.errors.should eq [] of String

    params = build_params("test_operation:age=not an int")
    operation = TestOperation.new(params)
    operation.age.value.should be_nil
    operation.age.errors.should eq ["is invalid"]
  end

  it "includes validations" do
    params = build_params("test_operation:name=")
    operation = TestOperation.new(params)
    operation.name.errors.should eq [] of String
    operation.valid?.should be_true

    operation.validate

    operation.name.errors.should eq ["is required"]
    operation.valid?.should be_false
  end

  describe "#errors" do
    it "includes errors for all attributes" do
      params = build_params("multi:name=&multi:age=20")
      operation = TestOperationWithMultipleValidations.new(params)

      operation.validate

      operation.errors.should eq({
        :name => ["is required"],
        :age  => ["is not old enough"],
      })
    end

    it "raises FailedOperation when the operation returns nil" do
      expect_raises(Avram::FailedOperation, "The operation failed to return a value") do
        FailingTestOperation.run!(name: "Mario")
      end
    end

    it "raises FailedOperation when the operation has validation errors" do
      expect_raises(Avram::FailedOperation, "The operation failed to return a value") do
        FailingTestOperation.run!
      end
    end
  end
end
