require "./spec_helper"

private class NeedsForm < User::BaseForm
  needs created_by : String
  needs nilable_value : String?
  needs optional : String = "bar"

  def prepare
    setup_required_fields
  end

  private def setup_required_fields
    name.value = "Joe"
    age.value = 62
    joined_at.value = Time.now
  end
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
end
