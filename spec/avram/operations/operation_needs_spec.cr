require "../../spec_helper"

include ParamHelper

private class OperationWithNeeds < Avram::Operation
  needs tags : Array(String)
  needs id : Int32
  attribute title : String
  attribute published : Bool = false
  file_attribute :image

  def run
    tags.join(", ")
  end
end

class Needs::SaveOperation < User::SaveOperation
  before_save prepare

  def prepare
    setup_required_attributes
  end

  private def setup_required_attributes
    name.value ||= "Joe"
    age.value ||= 62
    joined_at.value ||= Time.utc
  end
end

private class NeedsSaveOperation < Needs::SaveOperation
  needs created_by : String
  needs nilable_value : String?
  needs optional : String = "bar"
  attribute not_db_related : Int32
  file_attribute :image
end

private class NeedyDeleteOperation < Post::DeleteOperation
  needs user : User
  needs notification_message : String?
  needs no_number : Int32 = 4
  attribute confirm_delete : String
end

describe "Avram::Operation needs" do
  it "sets up named args for needs" do
    OperationWithNeeds.run(tags: ["one", "two"], id: 3) do |operation, value|
      value.should eq "one, two"
      operation.tags.should eq ["one", "two"]
      operation.id.should eq 3
    end
  end

  it "allows params to be passed in along with named args for needs" do
    params = Avram::Params.new({"title" => "test", "published" => "true"})

    OperationWithNeeds.run(params, tags: ["one", "two"], id: 3) do |operation, value|
      value.should eq "one, two"
      operation.tags.should eq ["one", "two"]
      operation.id.should eq 3
      operation.title.value.should eq "test"
      operation.published.value.should eq true
    end
  end

  it "sets up named args for file_attribute" do
    uploaded_file = Avram::UploadedFile.new("thumb.png")
    OperationWithNeeds.run(tags: ["one", "two"], id: 3, image: uploaded_file) do |operation, _value|
      operation.image.value.should be_a Avram::Uploadable
    end
  end
end

describe "Avram::SaveOperation needs" do
  it "sets up a method arg for save, update, and new" do
    params = Avram::Params.new({"name" => "Paul"})
    UserFactory.create
    user = UserQuery.new.first

    NeedsSaveOperation.create(params, nilable_value: "not nil", optional: "bar", created_by: "Jane") do |operation, _record|
      operation.nilable_value.should eq("not nil")
      operation.created_by.should eq("Jane")
      operation.optional.should eq("bar")
    end
    NeedsSaveOperation.update(user, params, nilable_value: nil, created_by: "Jane") do |operation, _record|
      operation.nilable_value.should be_nil
      operation.created_by.should eq("Jane")
    end

    NeedsSaveOperation.new(params, nilable_value: nil, created_by: "Jane")
  end

  it "also generates named args for other attributes" do
    uploaded_file = Avram::UploadedFile.new("thumb.png")
    NeedsSaveOperation.create(name: "Jane", nilable_value: "not nil", optional: "bar", created_by: "Jane", not_db_related: 4, image: uploaded_file) do |operation, _record|
      # Problem seems to be that params override passed in val
      operation.name.value.should eq("Jane")
      operation.nilable_value.should eq("not nil")
      operation.created_by.should eq("Jane")
      operation.optional.should eq("bar")
      operation.not_db_related.value.should eq(4)
      operation.image.value.as(Avram::UploadedFile).filename.should eq "thumb.png"
    end
  end
end

describe "Avram::DeleteOperation needs" do
  it "sets up a method arg for delete" do
    user = UserFactory.create
    post = PostFactory.create

    NeedyDeleteOperation.delete(post, user: user, notification_message: "is this thing on?") do |operation, _record|
      operation.notification_message.should eq("is this thing on?")
      operation.no_number.should eq(4)
      operation.user.should eq(user)
    end
  end

  it "also generates named args for other attributes" do
    params = build_params("post:confirm_delete=yeah,%20do%20it")
    user = UserFactory.create
    post = PostFactory.create

    NeedyDeleteOperation.delete(post, params, user: user, notification_message: nil) do |operation, _record|
      operation.notification_message.should be_nil
      operation.no_number.should eq(4)
      operation.user.should eq(user)
      operation.confirm_delete.value.should eq("yeah, do it")
    end
  end
end
