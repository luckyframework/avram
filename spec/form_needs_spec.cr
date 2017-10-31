require "./spec_helper"

private class NeedsForm < User::BaseForm
  needs created_by : String
  needs foo : String = "bar"

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
  it "sets up a method arg for save and update" do
    params = {"name" => "Paul"}
    create_user
    user = UserQuery.new.first

    form = NeedsForm.new(params, created_by: "Jane")
    form.created_by.should eq("Jane")
    NeedsForm.save(params, foo: "bar", created_by: "Jane") do |form, _record|
      form.created_by.should eq("Jane")
      form.foo.should eq("bar")
    end
    NeedsForm.update(user, params, created_by: "Jane") do |form, _record|
      form.created_by.should eq("Jane")
    end
  end
end
