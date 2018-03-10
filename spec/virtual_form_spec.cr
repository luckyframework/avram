require "./spec_helper"

private class TestVirtualForm < LuckyRecord::VirtualForm
  allow_virtual name : String
  allow_virtual age : Int32

  def validate
    validate_required name
  end
end

describe LuckyRecord::VirtualForm do
  it "sets a form_name" do
    TestVirtualForm.new.form_name.should eq "test_virtual"
    TestVirtualForm.form_name.should eq "test_virtual"
  end

  it "sets up initializers for params and no params" do
    virtual_form = TestVirtualForm.new
    virtual_form.name.value.should be_nil
    virtual_form.name.value = "Megan"
    virtual_form.name.value.should eq("Megan")

    params = LuckyRecord::Params.new({"name" => "Jordan"})
    virtual_form = TestVirtualForm.new(params)
    virtual_form.name.value.should eq("Jordan")
  end

  it "parses params" do
    params = LuckyRecord::Params.new({"age" => "45"})
    virtual_form = TestVirtualForm.new(params)
    virtual_form.age.value.should eq 45
    virtual_form.age.errors.should eq [] of String

    params = LuckyRecord::Params.new({"age" => "not an int"})
    virtual_form = TestVirtualForm.new(params)
    virtual_form.age.value.should be_nil
    virtual_form.age.errors.should eq ["is invalid"]
  end

  it "includes validations" do
    params = LuckyRecord::Params.new({"name" => ""})
    virtual_form = TestVirtualForm.new(params)
    virtual_form.name.errors.should eq [] of String
    virtual_form.valid?.should be_true

    virtual_form.validate

    virtual_form.name.errors.should eq ["is required"]
    virtual_form.valid?.should be_false
  end
end
