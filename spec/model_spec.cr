require "./spec_helper"

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
    user = UserBox.create
    post = PostBox.create

    user.id.should eq(post.id)
    user.should_not eq(post)
  end

  describe "reload" do
    it "can reload a model" do
      user = UserBox.create &.name("Original Name")

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
        post = PostBox.create

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
    UserBox.create
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
    it "can be saved" do
      uuid_regexp = /\w+/
      LineItemBox.create

      item = LineItemQuery.new.first
      item.id.to_s.should match(uuid_regexp)
    end

    it "can be deleted" do
      LineItemBox.create

      item = LineItemQuery.new.first
      item.delete

      LineItem::BaseQuery.all.size.should eq 0
    end
  end

  it "can infer the table name when omitted" do
    InferredTableNameModel.table_name.should eq(:inferred_table_name_models)
  end

  it "can infer table name for namedspaced models" do
    NamedSpaced::Model.table_name.should eq(:named_spaced_models)
  end
end
