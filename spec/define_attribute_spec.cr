require "./spec_helper"

private class Operation < Post::SaveOperation
  attribute password_confirmation : String
  attribute terms_of_service : Bool
  attribute best_kind_of_bear : String = "black bear"
  attribute default_is_false : Bool = false
  before_save prepare

  def prepare
    password_confirmation.value = "reset"
  end

  def setup_required_database_columns
    title.value = "Title"
  end
end

describe "attribute in forms" do
  it "is a PermittedAttribute" do
    operation.password_confirmation.should be_a(Avram::PermittedAttribute(String?))
    operation.password_confirmation.name.should eq(:password_confirmation)
    operation.password_confirmation.param_key.should eq("post")
  end

  it "generates a list of attributes" do
    operation.attributes.map(&.name).should eq [:password_confirmation,
                                                :terms_of_service,
                                                :best_kind_of_bear,
                                                :default_is_false]
  end

  it "sets a default value of nil if another one is not given" do
    operation.password_confirmation.value.should be_nil
    operation.terms_of_service.value.should be_nil
  end

  it "assigns the default value to an attribute if one is set and no param is given" do
    operation.best_kind_of_bear.value.should eq "black bear"
    operation.default_is_false.value.should be_false
  end

  it "overrides the default value with a param if one is given" do
    operation({"best_kind_of_bear" => "brown bear"}).best_kind_of_bear.value.should eq "brown bear"
    operation({"best_kind_of_bear" => ""}).best_kind_of_bear.value.should be_nil
  end

  it "sets the param and value basd on the passed in params" do
    operation = operation({"password_confirmation" => "password"})

    operation.password_confirmation.value.should eq "password"
    operation.password_confirmation.param.should eq "password"
  end

  it "is memoized so you can change the attribute in `prepare`" do
    operation = operation({"password_confirmation" => "password"})
    operation.password_confirmation.value.should eq "password"

    operation.prepare
    operation.password_confirmation.value.should eq "reset"
  end

  it "parses the value using the declared type" do
    operation = operation({"terms_of_service" => "1"})
    operation.terms_of_service.value.should be_true

    operation = operation({"terms_of_service" => "0"})
    operation.terms_of_service.value.should be_false
  end

  it "gracefully handles invalid params" do
    operation = operation({"terms_of_service" => "not a boolean"})
    operation.terms_of_service.value.should be_nil
    operation.terms_of_service.errors.first.should eq "is invalid"
  end

  it "includes attribute errors when calling SaveOperation#valid?" do
    operation = operation({"terms_of_service" => "not a boolean"})
    operation.setup_required_database_columns
    operation.valid?.should be_false
  end

  it "can still save to the database" do
    params = {"password_confirmation" => "password", "terms_of_service" => "1"}
    operation = operation(params)
    operation.setup_required_database_columns
    operation.save.should eq true
  end

  it "sets named args for attributes, leaves other empty" do
    Operation.create(title: "My Title", best_kind_of_bear: "brown bear") do |operation, post|
      operation.best_kind_of_bear.value.should eq("brown bear")
      operation.terms_of_service.value.should be_nil
      post.should_not be_nil

      Operation.update(post.not_nil!, best_kind_of_bear: "koala bear") do |operation, post|
        operation.best_kind_of_bear.value.should eq("koala bear")
      end
    end
  end
end

private def operation(attrs = {} of String => String)
  Operation.new(attrs)
end
