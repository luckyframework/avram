require "./spec_helper"

private class TestVirtualOperation < Avram::VirtualOperation
  virtual name : String
  virtual age : Int32

  def validate
    validate_required name
  end
end

private class TestVirtualOperationWithMultipleValidations < Avram::VirtualOperation
  virtual name : String
  virtual age : Int32

  def validate
    validate_required name
    validate_old_enough age
  end

  private def validate_old_enough(age_field)
    if (age = age_field.value) && age < 21
      age_field.add_error "is not old enough"
    end
  end
end

private class UserWithVirtual < User::SaveOperation
  virtual password : String
end

private class CanUseSameVirtualFieldTwiceInModelBackedSaveOperation < User::SaveOperation
  virtual password : String
end

private class CanUseSameVirtualFieldTwiceInVirtualOperation < Avram::VirtualOperation
  virtual name : String
end

private class ParamKeySaveOperation < Avram::VirtualOperation
  param_key :custom_param
end

describe Avram::VirtualOperation do
  it "has create/update args for virtual fields" do
    UserWithVirtual.create(password: "p@ssword") do |form, _user|
      form.password.value = "p@ssword"
    end

    user = UserBox.create
    UserWithVirtual.update(user, password: "p@ssword") do |form, _user|
      form.password.value = "p@ssword"
    end
  end

  it "sets a form_name" do
    TestVirtualOperation.new.form_name.should eq "test_virtual"
    TestVirtualOperation.form_name.should eq "test_virtual"
  end

  it "allows overriding the form_name" do
    ParamKeySaveOperation.new.form_name.should eq "custom_param"
    ParamKeySaveOperation.form_name.should eq "custom_param"
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

  describe "#fields" do
    it "equals `virtual_fields`" do
      virtual_form = TestVirtualOperation.new
      virtual_form.virtual_fields.should eq(virtual_form.fields)
    end
  end

  describe "#errors" do
    it "includes errors for all form fields" do
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
