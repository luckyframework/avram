require "./spec_helper"

private class VirtualOperation < Post::SaveOperation
  virtual password_confirmation : String
  virtual terms_of_service : Bool
  virtual best_kind_of_bear : String = "black bear"
  virtual default_is_false : Bool = false

  def prepare
    password_confirmation.value = "reset"
  end

  def setup_required_database_fields
    title.value = "Title"
  end
end

describe "virtual in forms" do
  it "is a FillableField" do
    form.password_confirmation.should be_a(Avram::FillableField(String?))
    form.password_confirmation.name.should eq(:password_confirmation)
    form.password_confirmation.form_name.should eq("virtual")
  end

  it "generates a list of fillable_fields" do
    form.virtual_fields.map(&.name).should eq [:password_confirmation,
                                               :terms_of_service,
                                               :best_kind_of_bear,
                                               :default_is_false]
  end

  it "sets a default value of nil if another one is not given" do
    form.password_confirmation.value.should be_nil
    form.terms_of_service.value.should be_nil
  end

  it "assigns the default value to a field if one is set and no param is given" do
    form.best_kind_of_bear.value.should eq "black bear"
    form.default_is_false.value.should be_false
  end

  it "overrides the default value with a param if one is given" do
    form({"best_kind_of_bear" => "brown bear"}).best_kind_of_bear.value.should eq "brown bear"
    form({"best_kind_of_bear" => ""}).best_kind_of_bear.value.should be_nil
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

  it "includes field errors when calling SaveOperation#valid?" do
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

  it "sets named args for virtual fields, leaves other empty" do
    VirtualOperation.create(title: "My Title", best_kind_of_bear: "brown bear") do |form, post|
      form.best_kind_of_bear.value.should eq("brown bear")
      form.terms_of_service.value.should be_nil
      post.should_not be_nil

      VirtualOperation.update(post.not_nil!, best_kind_of_bear: "koala bear") do |form, post|
        form.best_kind_of_bear.value.should eq("koala bear")
      end
    end
  end
end

private def form(attrs = {} of String => String)
  VirtualOperation.new(attrs)
end
