require "./spec_helper"

private class ModelWithCustomDataTypes < LuckyRecord::Model
  table :foo do
    field email : Email
  end
end

private class QueryMe < LuckyRecord::Model
  table :users do
    field email : Email
    field age : Int32
  end
end

describe LuckyRecord::Model do
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
    user = ModelWithCustomDataTypes.new id: 123,
      created_at: Time.now,
      updated_at: Time.now,
      email: " Foo@bar.com "

    user.email.should eq "foo@bar.com"
  end

  it "sets up simple methods for equality" do
    query = QueryMe::BaseQuery.new.email("foo@bar.com").age(30)

    query.to_sql.should eq ["SELECT * FROM users WHERE email = $1 AND age = $2", "foo@bar.com", "30"]
  end

  it "sets up advanced criteria methods" do
    query = QueryMe::BaseQuery.new.email.upper.is("foo@bar.com").age.gt(30)

    query.to_sql.should eq ["SELECT * FROM users WHERE UPPER(email) = $1 AND age > $2", "foo@bar.com", "30"]
  end
end
