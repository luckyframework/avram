require "./spec_helper"

private class TestOperation < Avram::Operation
  attribute name : String
  attribute age : Int32

  def validate
    validate_required name
  end
end

private class TestOperationWithMultipleValidations < Avram::Operation
  attribute name : String
  attribute age : Int32

  def validate
    validate_required name
    validate_old_enough age
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
end

private class ParamKeySaveOperation < Avram::Operation
  param_key :custom_param
end

private class NeedyOperation < Avram::SubmitOperation
  needs test_operation : TestOperation
  attribute secret : String

  def submit
    "The secret to #{test_operation.class} is #{secret.value}"
  end
end

private class FailedSubmitOp < Avram::SubmitOperation
  attribute option : String

  def submit
    validate_required option

    option
  end
end

describe Avram::Operation do
  it "has create/update args for non column attributes" do
    UserWithVirtual.create(password: "p@ssword") do |operation, _user|
      operation.password.value = "p@ssword"
    end

    user = UserBox.create
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

    params = Avram::Params.new({"name" => "Jordan"})
    operation = TestOperation.new(params)
    operation.name.value.should eq("Jordan")
  end

  it "parses params" do
    params = Avram::Params.new({"age" => "45"})
    operation = TestOperation.new(params)
    operation.age.value.should eq 45
    operation.age.errors.should eq [] of String

    params = Avram::Params.new({"age" => "not an int"})
    operation = TestOperation.new(params)
    operation.age.value.should be_nil
    operation.age.errors.should eq ["is invalid"]
  end

  it "includes validations" do
    params = Avram::Params.new({"name" => ""})
    operation = TestOperation.new(params)
    operation.name.errors.should eq [] of String
    operation.valid?.should be_true

    operation.validate

    operation.name.errors.should eq ["is required"]
    operation.valid?.should be_false
  end

  describe "#errors" do
    it "includes errors for all attributes" do
      params = Avram::Params.new({"name" => "", "age" => "20"})
      operation = TestOperationWithMultipleValidations.new(params)

      operation.validate

      operation.errors.should eq({
        :name => ["is required"],
        :age  => ["is not old enough"],
      })
    end
  end

  describe "using needs" do
    it "allows needs to be passed in" do
      test_op = TestOperation.new
      params = Avram::Params.new({"secret" => "shhh"})
      NeedyOperation.run(params, test_operation: test_op) do |op, result|
        result.should eq "The secret to TestOperation is shhh"
      end
    end
  end

  describe "a SubmitOperation using validations" do
    it "returns nil for the result when the validation fails" do
      params = Avram::Params.new({"nothing" => "true"})
      FailedSubmitOp.run(params) do |operation, result|
        result.should eq nil
        operation.valid?.should eq false
        operation.option.errors.should eq ["is required"]
      end
    end
  end
end
