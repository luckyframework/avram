require "./spec_helper"

class Needs::SaveOperation < User::SaveOperation
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

private class NeedsWithOnOptionSaveOperation < Needs::SaveOperation
  needs created_by : String, on: :create
  needs updated_by : String, on: :update
  needs saved_by : String, on: :save
end

describe "Avram::SaveOperation needs" do
  it "doesn't change the initializer if an 'on' option is used'" do
    params = {"name" => "Paul"}
    user = UserBox.create

    operation = NeedsWithOnOptionSaveOperation.new(params)
    operation.created_by.should be_nil
    operation.updated_by.should be_nil
    operation.saved_by.should be_nil
    operation = NeedsWithOnOptionSaveOperation.new(user, params)
    operation.created_by.should be_nil
    operation.updated_by.should be_nil
    operation.saved_by.should be_nil
  end

  it "sets up a method arg for save, update, and new" do
    params = {"name" => "Paul"}
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

  it "can have needs for just save, create or update" do
    params = {"name" => "Paul"}
    UserBox.create
    user = UserQuery.new.first

    NeedsWithOnOptionSaveOperation.create(params, saved_by: "Me", created_by: "Bob") do |operation, _record|
      operation.created_by.should eq("Bob")
      operation.updated_by.should be_nil
    end
    NeedsWithOnOptionSaveOperation.update(user, params, saved_by: "Me", updated_by: "Laura") do |operation, _record|
      operation.created_by.should be_nil
      operation.updated_by.should eq("Laura")
    end
  end
end
