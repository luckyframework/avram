require "../../spec_helper"

include ParamHelper

private class OperationWithAttributes < Avram::Operation
  param_key :data
  attribute title : String
  attribute count : Int32
  attribute checked : Bool = false
  attribute thing : String = "taco"
  file_attribute :thumb

  def update_count
    count.value = 4
  end

  def run
    [title, count]
  end
end

private class SaveOperationWithAttributes < Post::SaveOperation
  attribute password_confirmation : String
  attribute terms_of_service : Bool
  attribute best_kind_of_bear : String = "black bear"
  attribute default_is_false : Bool = false
  file_attribute :thumb

  before_save prepare

  def prepare
    password_confirmation.value = "reset"
  end

  def setup_required_database_columns
    title.value = "Title"
  end
end

private class DeleteOperationWithAttributes < Post::DeleteOperation
  attribute accept_delete : Bool = false
  attribute confirm_delete : String
  file_attribute :biometric_confirmation

  before_delete :ensure_confirmation_matches

  private def ensure_confirmation_matches
    if confirm_delete.value != "DELETE ME FOR REALZ"
      confirm_delete.add_error("text must match")
    end
  end
end

describe "attribute in operations" do
  it "is a PermittedAttribute" do
    operation.title.should be_a(Avram::PermittedAttribute(String))
    operation.title.name.should eq(:title)
    operation.title.param_key.should eq("data")

    save_operation.password_confirmation.should be_a(Avram::PermittedAttribute(String))
    save_operation.password_confirmation.name.should eq(:password_confirmation)
    save_operation.password_confirmation.param_key.should eq("post")

    delete_operation.accept_delete.should be_a(Avram::PermittedAttribute(Bool))
    delete_operation.accept_delete.name.should eq(:accept_delete)
    delete_operation.accept_delete.param_key.should eq("post")
  end

  it "generates a list of attributes" do
    operation.attributes.map(&.name).should eq [:thumb, :thing, :checked, :count, :title]

    save_operation.attributes.map(&.name).should eq [
      :thumb,
      :default_is_false,
      :best_kind_of_bear,
      :terms_of_service,
      :password_confirmation,
      :custom_id,
      :created_at,
      :updated_at,
      :title,
      :published_at,
    ]

    delete_operation.attributes.map(&.name).should eq [
      :biometric_confirmation,
      :confirm_delete,
      :accept_delete,
      :custom_id,
      :created_at,
      :updated_at,
      :title,
      :published_at,
    ]
  end

  it "sets a default value of nil if another one is not given" do
    operation.title.value.should be_nil
    operation.count.value.should be_nil
    save_operation.password_confirmation.value.should be_nil
    save_operation.terms_of_service.value.should be_nil
    delete_operation.confirm_delete.value.should be_nil
  end

  it "assigns the default value to an attribute if one is set and no param is given" do
    operation.checked.value.should eq false
    operation.thing.value.should eq "taco"
    save_operation.best_kind_of_bear.value.should eq "black bear"
    save_operation.default_is_false.value.should be_false
    delete_operation.accept_delete.value.should be_false
  end

  it "overrides the default value with a param if one is given" do
    operation("data:title=Random+Food").title.value.should eq "Random Food"
    operation("data:count=4").count.value.should eq 4
    operation("data:checked=true").checked.value.should eq true
    save_operation("post:best_kind_of_bear=brown+bear").best_kind_of_bear.value.should eq "brown bear"
    save_operation("post:best_kind_of_bear=").best_kind_of_bear.value.should be_nil
    delete_operation("post:accept_delete=true").accept_delete.value.should be_true
  end

  it "sets the param and value based on the passed in params" do
    operation = operation("data:title=secret")
    operation.title.value.should eq "secret"
    operation.title.param.should eq "secret"

    save_operation = save_operation("post:password_confirmation=password")
    save_operation.password_confirmation.value.should eq "password"
    save_operation.password_confirmation.param.should eq "password"

    delete_operation = delete_operation("post:confirm_delete=yeah sure")
    delete_operation.confirm_delete.value.should eq "yeah sure"
    delete_operation.confirm_delete.param.should eq "yeah sure"
  end

  it "is memoized so you can change the attribute in `prepare`" do
    operation = save_operation("post:password_confirmation=password")
    operation.password_confirmation.value.should eq "password"

    operation.prepare
    operation.password_confirmation.value.should eq "reset"
  end

  it "parses the value using the declared type" do
    operation = save_operation("post:terms_of_service=1")
    operation.terms_of_service.value.should be_true

    operation = save_operation("post:terms_of_service=0")
    operation.terms_of_service.value.should be_false
  end

  it "gracefully handles invalid params" do
    operation = save_operation("post:terms_of_service=not a boolean")
    operation.terms_of_service.value.should be_nil
    operation.terms_of_service.errors.first.should eq "is invalid"
  end

  it "includes attribute errors when calling SaveOperation#valid?" do
    params = Avram::Params.new({"terms_of_service" => "not a boolean"})
    operation = SaveOperationWithAttributes.new(params)
    operation.setup_required_database_columns
    operation.valid?.should be_false
  end

  it "can still save to the database" do
    params = Avram::Params.new({"password_confirmation" => "password", "terms_of_service" => "1"})
    operation = SaveOperationWithAttributes.new(params)
    operation.setup_required_database_columns
    operation.save.should eq true
  end

  it "sets named args for attributes, leaves other empty" do
    SaveOperationWithAttributes.create(title: "My Title", best_kind_of_bear: "brown bear") do |operation, post|
      operation.best_kind_of_bear.value.should eq("brown bear")
      operation.terms_of_service.value.should be_nil
      post.should_not be_nil

      SaveOperationWithAttributes.update(post.as(Post), best_kind_of_bear: "koala bear") do |op, _post|
        op.best_kind_of_bear.value.should eq("koala bear")
      end
    end
  end
end

describe "file_attribute in operation" do
  it "is a PermittedAttribute" do
    operation.thumb.should be_a(Avram::PermittedAttribute(Avram::Uploadable))
    operation.thumb.name.should eq(:thumb)
    operation.thumb.param_key.should eq("data")

    save_operation.thumb.should be_a(Avram::PermittedAttribute(Avram::Uploadable))
    save_operation.thumb.name.should eq(:thumb)
    save_operation.thumb.param_key.should eq("post")

    delete_operation.biometric_confirmation.should be_a(Avram::PermittedAttribute(Avram::Uploadable))
    delete_operation.biometric_confirmation.name.should eq(:biometric_confirmation)
    delete_operation.biometric_confirmation.param_key.should eq("post")
  end

  it "is included in the list of attributes" do
    operation.attributes.map(&.name).should contain(:thumb)
    save_operation.attributes.map(&.name).should contain(:thumb)
    delete_operation.attributes.map(&.name).should contain(:biometric_confirmation)
  end

  it "gracefully handles invalid params" do
    params = Avram::Params.new({"thumb" => "not a file"})
    operation = OperationWithAttributes.new(params)
    operation.thumb.value.should be_nil
    operation.thumb.errors.first.should eq "is invalid"

    save_operation = SaveOperationWithAttributes.new(params)
    save_operation.thumb.value.should be_nil
    save_operation.thumb.errors.first.should eq "is invalid"

    params = Avram::Params.new({"biometric_confirmation" => "not a file"})
    post = PostFactory.create
    delete_operation = DeleteOperationWithAttributes.new(post, params)
    delete_operation.biometric_confirmation.value.should be_nil
    delete_operation.biometric_confirmation.errors.first.should eq "is invalid"
  end

  it "includes file attribute errors when calling SaveOperation#valid?" do
    params = Avram::Params.new({"thumb" => "not a file"})
    operation = SaveOperationWithAttributes.new(params)
    operation.setup_required_database_columns
    operation.valid?.should be_false
  end

  it "can still save to the database" do
    params = {"thumb" => Avram::UploadedFile.new("thumb.png")}
    operation = upload_save_operation(params)
    operation.setup_required_database_columns
    operation.save.should eq true
  end
end

private def operation(body : String)
  params = build_params(body)
  OperationWithAttributes.new(params)
end

private def operation
  OperationWithAttributes.new
end

private def save_operation(body : String)
  params = build_params(body)
  SaveOperationWithAttributes.new(params)
end

private def save_operation
  SaveOperationWithAttributes.new
end

private def upload_save_operation(attrs = {} of String => Avram::Uploadable)
  SaveOperationWithAttributes.new(Avram::UploadParams.new(attrs))
end

private def delete_operation(body : String)
  params = build_params(body)
  post = PostFactory.create
  DeleteOperationWithAttributes.new(post, params)
end

private def delete_operation
  post = PostFactory.create
  DeleteOperationWithAttributes.new(post)
end
