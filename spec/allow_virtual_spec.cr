require "./spec_helper"

private class VirtualForm < Post::BaseForm
  allow_virtual password_confirmation : String
  allow_virtual terms_of_service : Bool

  def prepare
    password_confirmation.value = "reset"
  end

  def setup_required_database_fields
    title.value = "Title"
  end
end

describe "allow_virtual in forms" do
  it "is an AllowedField" do
    form.password_confirmation.should be_a(LuckyRecord::AllowedField(String?))
    form.password_confirmation.name.should eq(:password_confirmation)
    form.password_confirmation.form_name.should eq("virtual")
  end

  it "generates a list of allowed_fields" do
    form.virtual_fields.map(&.name).should eq [:password_confirmation, :terms_of_service]
  end

  it "sets the param and value basd on the passed in params" do
    form = form({"password_confirmation" => "password"})

    form.password_confirmation.value.should eq "password"
    form.password_confirmation.param.should eq "password"
  end

  it "is memoized so you can change the field in `prepare`" do
    form = form({"password_confirmation" => "password"})
    form.password_confirmation.value.should eq "password"

    form.prepare
    form.password_confirmation.value.should eq "reset"
  end

  it "parses the value using the declared type" do
    form = form({"terms_of_service" => "1"})
    form.terms_of_service.value.should be_true

    form = form({"terms_of_service" => "0"})
    form.terms_of_service.value.should be_false
  end

  it "gracefully handles invalid params" do
    form = form({"terms_of_service" => "not a boolean"})
    form.terms_of_service.value.should be_nil
    form.terms_of_service.errors.first.should eq "is invalid"
  end

  it "includes field errors when calling Form#valid?" do
    form = form({"terms_of_service" => "not a boolean"})
    form.setup_required_database_fields
    form.valid?.should be_false
  end

  it "can still save to the database" do
    params = {"password_confirmation" => "password", "terms_of_service" => "1"}
    form = form(params)
    form.setup_required_database_fields
    form.save.should eq true
  end
end

private def form(attrs = {} of String => String)
  VirtualForm.new(attrs)
end
