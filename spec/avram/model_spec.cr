require "../spec_helper"

include LazyLoadHelpers

class NamedSpaced::Model < BaseModel
  table do
  end
end

private class QueryMe < BaseModel
  COLUMN_SQL = "users.id, users.created_at, users.updated_at, users.email, users.age"

  table :users do
    column email : CustomEmail
    column age : Int32
  end
end

private class EmptyModelCompilesOk < BaseModel
  table :no_fields do
  end
end

private class InferredTableNameModel < BaseModel
  COLUMN_SQL = "inferred_table_name_models.id, inferred_table_name_models.created_at, inferred_table_name_models.updated_at"

  table do
  end
end

describe Avram::Model do
  it "compares with id and model name, not just id" do
    user = UserFactory.create
    post = PostFactory.create

    user.should_not eq(post)
  end

  it "sets up initializers based on the columns" do
    now = Time.utc

    user = User.new id: 123_i64,
      name: "Name",
      age: 24,
      year_born: 1990_i16,
      joined_at: now,
      created_at: now,
      updated_at: now,
      nickname: "nick",
      total_score: nil,
      average_score: nil,
      available_for_hire: nil

    user.name.should eq "Name"
    user.age.should eq 24
    user.year_born.should eq 1990_i16
    user.joined_at.should eq now
    user.updated_at.should eq now
    user.created_at.should eq now
    user.nickname.should eq "nick"
    user.available_for_hire.should be_nil
    user.available_for_hire?.should be_false
  end

  it "can be used for params" do
    now = Time.utc

    user = User.new id: 123_i64,
      name: "Name",
      age: 24,
      year_born: 1990_i16,
      joined_at: now,
      created_at: now,
      updated_at: now,
      nickname: "nick",
      total_score: nil,
      average_score: nil,
      available_for_hire: nil

    user.to_param.should eq "123"
  end

  it "sets up getters that parse the values" do
    user = QueryMe.new id: 123_i64,
      created_at: Time.utc,
      updated_at: Time.utc,
      age: 30,
      email: " Foo@bar.com "

    user.email.should be_a(CustomEmail)
    user.email.to_s.should eq "foo@bar.com"
  end

  describe "reload" do
    it "can reload a model" do
      user = UserFactory.create &.name("Original Name")

      # Update returns a brand new user. It should have the new name
      newly_updated_user = User::SaveOperation.update!(user, name: "Updated Name")

      newly_updated_user.name.should eq("Updated Name")
      # The original user is not modified
      user.name.should eq("Original Name")
      # So we reload it to get the new goodies
      user.reload.name.should eq("Updated Name")
    end

    it "can reload a model with a yielded query" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create

        # If `preload_tags` doesn't work this will raise
        post.reload(&.preload_tags).tags.should be_empty
      end
    end
  end

  it "sets up simple methods for equality" do
    query = QueryMe::BaseQuery.new.email("foo@bar.com").age(30)

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE users.email = $1 AND users.age = $2", "foo@bar.com", "30"]
  end

  it "sets up advanced criteria methods" do
    query = QueryMe::BaseQuery.new.email.upper.eq("foo@bar.com").age.gt(30)

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE UPPER(users.email) = $1 AND users.age > $2", "foo@bar.com", "30"]
  end

  it "parses values" do
    query = QueryMe::BaseQuery.new.email.upper.eq(" Foo@bar.com").age.gt(30)

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users WHERE UPPER(users.email) = $1 AND users.age > $2", "foo@bar.com", "30"]
  end

  it "lets you order by columns" do
    query = QueryMe::BaseQuery.new.age.asc_order.email.desc_order

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMN_SQL} FROM users ORDER BY users.age ASC, users.email DESC"]
  end

  it "can be deleted" do
    UserFactory.create
    user = UserQuery.new.first

    user.delete

    User::BaseQuery.all.size.should eq 0
  end

  describe ".column_names" do
    it "returns list of mapped columns" do
      QueryMe.column_names.should eq [:id, :created_at, :updated_at, :email, :age]
    end
  end

  describe "models with uuids" do
    it "sets up initializers accepting uuid strings" do
      uuid = UUID.new("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      LineItem.new(uuid, Time.utc, Time.utc, "hello")
    end

    it "can be saved" do
      LineItemFactory.create

      item = LineItemQuery.new.first
      item.id.should be_a UUID
    end

    it "can be deleted" do
      LineItemFactory.create

      item = LineItemQuery.new.first
      item.delete

      LineItem::BaseQuery.all.size.should eq 0
    end
  end

  it "can infer the table name when omitted" do
    InferredTableNameModel.table_name.should eq("inferred_table_name_models")
  end

  it "can infer table name for namedspaced models" do
    NamedSpaced::Model.table_name.should eq("named_spaced_models")
  end
end
