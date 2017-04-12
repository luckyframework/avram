require "../spec_helper"

private class SchemaWithCustomDataTypes < LuckyRecord::Schema
  table :foo do
    field :email, LuckyRecord::EmailType
  end
end

describe LuckyRecord::Schema do
  it "sets up initializers based on the fields" do
    now = Time.now

    user = User.new id: 123,
      name: "Name",
      age: 24,
      joined_at: now,
      created_at: now,
      updated_at: now,
      nickname: "nick"

    user.name.should eq "Name"
    user.age.should eq 24
    user.joined_at.should eq now
    user.updated_at.should eq now
    user.created_at.should eq now
    user.nickname.should eq "nick"
  end

  it "sets up getters that cast the values" do
    user = SchemaWithCustomDataTypes.new id: 123,
      created_at: Time.now,
      updated_at: Time.now,
      email: " Foo@bar.com "

    user.email.should eq "foo@bar.com"
  end
end
