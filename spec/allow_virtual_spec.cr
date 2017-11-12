require "./spec_helper"

private class VirtualForm < User::BaseForm
  allow_virtual password_confirmation : String?
  allow_virtual terms_of_service : Bool?

  def prepare
    password_confirmation.value = "reset"
  end
end

describe "allow_virtual in forms" do
  it "is an AllowedField" do
    form.password_confirmation.should be_a(LuckyRecord::AllowedField(String?))
    form.password_confirmation.name.should eq(:password_confirmation)
    form.password_confirmation.form_name.should eq("virtual")
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

  it "parses the value using the given type" do
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
end

private def form(attrs = {} of String => String)
  VirtualForm.new(attrs)
end
