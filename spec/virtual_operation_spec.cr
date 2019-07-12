require "./spec_helper"

private class TestVirtualOperation < Avram::VirtualOperation
  attribute name : String
  attribute age : Int32

  def validate
    validate_required name
  end
end

private class TestVirtualOperationWithMultipleValidations < Avram::VirtualOperation
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

private class CanUseSameVirtualAttributeTwiceInVirtualOperation < Avram::VirtualOperation
  attribute name : String
end

private class ParamKeySaveOperation < Avram::VirtualOperation
  param_key :custom_param
end

describe Avram::VirtualOperation do
  it "has create/update args for non column attributes" do
    UserWithVirtual.create(password: "p@ssword") do |form, _user|
      form.password.value = "p@ssword"
    end

    user = UserBox.create
    UserWithVirtual.update(user, password: "p@ssword") do |form, _user|
      form.password.value = "p@ssword"
    end
  end

  it "sets a param_key based on the underscored class name" do
    TestVirtualOperation.param_key.should eq "test_virtual_operation"
  end

  it "allows overriding the param_key" do
    ParamKeySaveOperation.param_key.should eq "custom_param"
  end

  it "sets up initializers for params and no params" do
    virtual_form = TestVirtualOperation.new
    virtual_form.name.value.should be_nil
    virtual_form.name.value = "Megan"
    virtual_form.name.value.should eq("Megan")

    params = Avram::Params.new({"name" => "Jordan"})
    virtual_form = TestVirtualOperation.new(params)
    virtual_form.name.value.should eq("Jordan")
  end

  it "parses params" do
    params = Avram::Params.new({"age" => "45"})
    virtual_form = TestVirtualOperation.new(params)
    virtual_form.age.value.should eq 45
    virtual_form.age.errors.should eq [] of String

    params = Avram::Params.new({"age" => "not an int"})
    virtual_form = TestVirtualOperation.new(params)
    virtual_form.age.value.should be_nil
    virtual_form.age.errors.should eq ["is invalid"]
  end

  it "includes validations" do
    params = Avram::Params.new({"name" => ""})
    virtual_form = TestVirtualOperation.new(params)
    virtual_form.name.errors.should eq [] of String
    virtual_form.valid?.should be_true

    virtual_form.validate

    virtual_form.name.errors.should eq ["is required"]
    virtual_form.valid?.should be_false
  end

  describe "#errors" do
    it "includes errors for all attributes" do
      params = Avram::Params.new({"name" => "", "age" => "20"})
      form = TestVirtualOperationWithMultipleValidations.new(params)

      form.validate

      form.errors.should eq({
        :name => ["is required"],
        :age  => ["is not old enough"],
      })
    end
  end
end
