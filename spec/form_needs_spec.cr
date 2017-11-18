require "./spec_helper"

class Needs::BaseForm < User::BaseForm
  def prepare
    setup_required_fields
  end

  private def setup_required_fields
    name.value = "Joe"
    age.value = 62
    joined_at.value = Time.now
  end
end

private class NeedsForm < Needs::BaseForm
  needs created_by : String
  needs nilable_value : String?
  needs optional : String = "bar"
end

private class NeedsWithOnOptionForm < Needs::BaseForm
  needs created_by : String, on: :create
  needs updated_by : String, on: :update
end

describe "LuckyRecord::Form needs" do
  it "does not change the default initializer" do
    params = {"name" => "Paul"}
    create_user
    user = UserQuery.new.first

    form = NeedsForm.new(params)
    form.created_by.should be_nil
    form = NeedsForm.new(user, params)
    form.created_by.should be_nil
  end

  it "sets up a method arg for save and update" do
    params = {"name" => "Paul"}
    create_user
    user = UserQuery.new.first

    NeedsForm.save(params, nilable_value: "not nil", optional: "bar", created_by: "Jane") do |form, _record|
      form.nilable_value.should eq("not nil")
      form.created_by.should eq("Jane")
      form.optional.should eq("bar")
    end
    NeedsForm.update(user, params, nilable_value: nil, created_by: "Jane") do |form, _record|
      form.nilable_value.should be_nil
      form.created_by.should eq("Jane")
    end
  end

  it "can have needs for just create or update" do
    params = {"name" => "Paul"}
    create_user
    user = UserQuery.new.first

    NeedsWithOnOptionForm.save(params, created_by: "Bob") do |form, _record|
      form.created_by.should eq("Bob")
      form.updated_by.should be_nil
    end
    NeedsWithOnOptionForm.update(user, params, updated_by: "Laura") do |form, _record|
      form.created_by.should be_nil
      form.updated_by.should eq("Laura")
    end
  end
end
