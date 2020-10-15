require "./spec_helper"

private class OperationWithNeeds < Avram::Operation
  needs tags : Array(String)
  needs id : Int32
  attribute title : String
  attribute published : Bool = false

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
end

describe "Avram::SaveOperation needs" do
  it "sets up a method arg for save, update, and new" do
    params = Avram::Params.new({"name" => "Paul"})
    UserBox.create
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
    NeedsSaveOperation.create(name: "Jane", nilable_value: "not nil", optional: "bar", created_by: "Jane") do |operation, _record|
      # Problem seems to be that params override passed in val
      operation.name.value.should eq("Jane")
      operation.nilable_value.should eq("not nil")
      operation.created_by.should eq("Jane")
      operation.optional.should eq("bar")
    end
  end
end
