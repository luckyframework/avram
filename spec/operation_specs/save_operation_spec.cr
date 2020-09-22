require "../spec_helper"

private class ValueColumnModel < BaseModel
  table :value_column_model do
    column value : String
  end
end

private class ParamKeySaveOperation < ValueColumnModel::SaveOperation
  param_key :custom_param
end

private class SaveLimitedUser < User::SaveOperation
  permit_columns :name
end

private class SaveUser < User::SaveOperation
  attribute should_not_override_permitted_columns : String
  permit_columns :name, :nickname, :joined_at, :age
  attribute set_from_init : String
  before_save prepare

  def prepare
    validate_required name, joined_at, age
  end
end

private class SaveTask < Task::SaveOperation
end

private class ValidSaveOperationWithoutParams < Post::SaveOperation
  before_save prepare

  def prepare
    title.value = "My Title"
  end
end

private class SaveLineItem < LineItem::SaveOperation
  permit_columns :name
end

private class ValueColumnModelSaveOperation < ValueColumnModel::SaveOperation
  permit_columns value
end

private class SavePost < Post::SaveOperation
  permit_columns :title, :published_at
end

private def now_as_string
  Time.utc.to_s("%FT%X%z")
end

describe Avram::SaveOperation do
  describe ".create" do
    it "can create without params" do
      ValidSaveOperationWithoutParams.create do |operation, record|
        operation.saved?.should be_true
        record.is_a?(Post).should be_true
      end
    end

    context "on success" do
      it "yields the operation and the saved record" do
        params = Avram::Params.new({"joined_at" => now_as_string, "name" => "New Name", "age" => "30"})
        SaveUser.create params do |operation, record|
          operation.saved?.should be_true
          record.is_a?(User).should be_true
        end
      end
    end

    context "on failure" do
      it "yields the operation and nil" do
        params = Avram::Params.new({"name" => "", "age" => "30"})
        SaveUser.create params do |operation, record|
          operation.save_failed?.should be_true
          record.should be_nil
        end
      end

      it "logs the failure" do
        Avram::SaveFailedLog.dexter.temp_config do |log_io|
          SaveUser.create(name: "", age: 30) { |_operation, _record| :unused }
          log_io.to_s.should contain(%("failed_to_save" => "SaveUser", "validation_errors" => "name is required. joined_at is required"))
        end
      end
    end

    context "with a uuid backed model" do
      it "can create with params" do
        params = Avram::Params.new({"name" => "A fancy hat"})
        SaveLineItem.create params do |operation, record|
          operation.saved?.should be_true
          record.should be_a(LineItem)
        end
      end
    end
  end

  describe ".create!" do
    it "can create without params" do
      post = ValidSaveOperationWithoutParams.create!
      post.title.should eq("My Title")
    end

    context "on success" do
      it "saves and returns the record" do
        params = Avram::Params.new({"joined_at" => now_as_string, "name" => "New Name", "age" => "30"})

        record = SaveUser.create!(params)

        record.is_a?(User).should be_true
        record.name.should eq "New Name"
      end
    end

    context "on failure" do
      it "raises an exception" do
        params = Avram::Params.new({"name" => "", "age" => "30"})

        expect_raises Avram::InvalidOperationError do
          SaveUser.create!(params)
        end
      end
    end

    context "with a uuid backed model" do
      it "can manually set a uuid" do
        SaveLineItem.create!(
          id: UUID.new("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"),
          name: "A fancy hat"
        )
        LineItemQuery.new.id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11").select_count.should eq 1
      end
    end

    it "can handle an attribute named 'value'" do
      ValueColumnModelSaveOperation.new(Avram::Params.new({"value" => "value"})).value.value.should eq "value"
    end
  end

  describe ".update" do
    it "can create without params" do
      post = PostBox.new.title("Original Title").create
      ValidSaveOperationWithoutParams.update(post) do |operation, record|
        operation.saved?.should be_true
        record.title.should eq "My Title"
      end
    end

    context "on success" do
      it "yields the operation and the updated record" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = Avram::Params.new({"name" => "New Name"})
        SaveUser.update user, with: params do |operation, record|
          operation.saved?.should be_true
          record.name.should eq "New Name"
        end
      end

      it "updates updated_at" do
        user = UserBox.new.updated_at(1.day.ago).create
        params = Avram::Params.new({"name" => "New Name"})
        SaveUser.update user, with: params do |operation, record|
          operation.saved?.should be_true
          record.updated_at.should be > 1.second.ago
        end
      end
    end

    context "on failure" do
      it "yields the operation and nil" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = Avram::Params.new({"name" => ""})
        SaveUser.update user, with: params do |operation, record|
          operation.save_failed?.should be_true
          record.name.should eq "Old Name"
        end
      end

      it "logs the failure" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first

        Avram::SaveFailedLog.dexter.temp_config do |log_io|
          SaveUser.update(user, name: "") { |_operation, _record| :unused }
          log_io.to_s.should contain(%("failed_to_save" => "SaveUser", "validation_errors" => "name is required"))
        end
      end
    end

    context "with a uuid backed model" do
      it "doesn't generate a new uuid" do
        line_item = LineItemBox.create
        SaveLineItem.update(line_item, Avram::Params.new({"name" => "Another pair of shoes"})) do |operation, record|
          operation.saved?.should be_true
          record.id.should eq line_item.id
        end
      end
    end

    context "updating with no changes" do
      it "works when there are no changes" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = Avram::Params.new({} of String => String)
        SaveUser.update user, with: params do |operation, _record|
          operation.saved?.should be_true
        end
      end

      it "returns true when there are no changes" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        SaveUser.new(user).tap do |operation|
          operation.save.should be_true
        end
      end
    end
  end

  describe ".update!" do
    it "can create without params" do
      post = PostBox.new.title("Original Title").create
      post = ValidSaveOperationWithoutParams.update!(post)
      post.title.should eq "My Title"
    end

    context "on success" do
      it "updates and returns the record" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = Avram::Params.new({"name" => "New Name"})

        record = SaveUser.update! user, with: params

        record.is_a?(User).should be_true
        record.name.should eq "New Name"
      end
    end

    context "on failure" do
      it "raises an exception" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = Avram::Params.new({"name" => ""})

        expect_raises Avram::InvalidOperationError do
          SaveUser.update! user, with: params
        end
      end
    end
  end

  describe ".param_key" do
    it "allows overriding the param_key" do
      ParamKeySaveOperation.param_key.should eq "custom_param"
    end

    it "generates the correct param_key based on the model class" do
      SaveLimitedUser.param_key.should eq "user"
    end
  end

  describe ".permit_columns" do
    it "ignores params that are not permitted" do
      params = Avram::Params.new({"name" => "someone", "nickname" => "nothing"})
      SaveLimitedUser.create(params) do |operation, _value|
        operation.changes.has_key?(:nickname).should be_false
        operation.changes[:name]?.should eq "someone"
      end
    end

    it "returns a Avram::PermittedAttribute" do
      params = Avram::Params.new({"name" => "someone", "nickname" => "nothing"})
      SaveLimitedUser.create(params) do |operation, _value|
        operation.nickname.value.should be_nil
        operation.nickname.is_a?(Avram::Attribute).should be_true
        operation.name.value.should eq "someone"
        operation.name.is_a?(Avram::PermittedAttribute).should be_true
      end
    end
  end

  describe "initializer" do
    it "works with a record and named args" do
      UserBox.new.name("Old Name").create
      params = Avram::Params.new(name: "New Name")
      user = UserQuery.new.first

      operation = SaveUser.new(user, params)

      operation.name.value.should eq "New Name"
    end

    it "allows setting attributes" do
      operation = SaveUser.new(name: "Tracy", set_from_init: "success")
      operation.name.value.should eq("Tracy")
      operation.set_from_init.value.should eq("success")
    end
  end

  describe "#attributes" do
    it "creates a method for each of the permit_columns attributes" do
      params = Avram::Params.new({} of String => String)
      operation = SaveLimitedUser.new(params)

      operation.responds_to?(:name).should be_true
      operation.responds_to?(:nickname).should be_true
    end

    it "returns an Array of Avram::PermittedAttribute | Avram::Attribute" do
      operation = SaveUser.new

      attributes = operation.attributes.map(&.name)

      # attributes
      attributes.should contain :set_from_init

      # default columns
      attributes.should contain :id
      attributes.should contain :created_at
      attributes.should contain :updated_at

      # permitted columns
      attributes.should contain :name
      attributes.should contain :nickname
    end

    it "returns an attribute with the attribute name, value and errors" do
      params = Avram::Params.new({"name" => "Joe"})
      operation = SaveUser.new(params)
      operation.name.add_error "wrong"

      operation.name.name.should eq :name
      operation.name.value.should eq "Joe"
      operation.name.errors.should eq ["wrong"]
    end
  end

  describe "#required_attributes" do
    it "returns the required attributes" do
      operation = SaveTask.new
      operation.required_attributes.should eq({operation.title})
    end

    it "automatically runs validations for required attributes" do
      operation = SaveTask.new

      operation.valid?

      operation.valid?.should be_false
      operation.title.errors.size.should eq 1
      operation.body.errors.size.should eq 0
    end
  end

  describe "#errors" do
    it "includes errors for all operation attributes" do
      operation = SaveUser.new

      operation.valid?

      operation.errors.should eq({
        :name      => ["is required"],
        :age       => ["is required"],
        :joined_at => ["is required"],
      })
    end

    it "creates an error method for each of the permit_columns attributes" do
      params = Avram::Params.new({"name" => "Paul", "age" => "30", "joined_at" => now_as_string})
      operation = SaveUser.new(params)
      operation.valid?.should be_true

      operation.name.add_error "is not valid"

      operation.valid?.should be_false
      operation.name.errors.should eq ["is not valid"]
      operation.age.errors.should eq [] of String
    end

    it "only returns unique errors" do
      params = Avram::Params.new({"name" => "Paul", "nickname" => "Pablito"})
      operation = SaveUser.new(params)

      operation.name.add_error "is not valid"
      operation.name.add_error "is not valid"

      operation.name.errors.should eq ["is not valid"]
    end
  end

  describe "#save_failed?" do
    it "is true if the object is invalid and performed an action" do
      params = Avram::Params.new(name: "")
      operation = SaveUser.new(params)

      operation.save

      operation.save_failed?.should be_true
      operation.save_status.should eq(Avram::SaveOperation::SaveStatus::SaveFailed)
      operation.valid?.should be_false
    end

    it "is false if the object is not marked as saved but no action was performed" do
      params = Avram::Params.new(name: "")
      operation = SaveUser.new(params)

      operation.save_failed?.should be_false
      operation.save_status.should eq(Avram::SaveOperation::SaveStatus::Unperformed)
      operation.saved?.should be_false
      operation.valid?.should be_false
    end
  end

  describe "handling params" do
    it "creates a param method for each of the permit_columns attributes" do
      params = Avram::Params.new({"name" => "Paul", "nickname" => "Pablito"})

      operation = SaveUser.new(params)

      operation.name.param.should eq "Paul"
      operation.nickname.param.should eq "Pablito"
    end

    it "uses the value if param is empty" do
      user = UserBox.build

      operation = SaveUser.new(user, Avram::Params.new({} of String => String))

      operation.name.param.should eq user.name
    end

    it "sets the values" do
      params = Avram::Params.new({"name" => "Paul", "nickname" => "Pablito"})

      operation = SaveUser.new(params)

      operation.name.value.should eq "Paul"
      operation.nickname.value.should eq "Pablito"
      operation.age.value.should eq nil
    end

    it "returns the value from params for updates" do
      user = UserBox.build
      params = {"name" => "New Name From Params"}
      avram_params = Avram::Params.new(params)

      operation = SaveUser.new(user, avram_params)

      operation.name.value.should eq params["name"]
      operation.nickname.value.should eq user.nickname
      operation.age.value.should eq user.age
    end

    it "parse integers, time objects, etc. from param strings" do
      time = 1.day.ago.at_beginning_of_minute
      operation = SaveUser.new(Avram::Params.new({"joined_at" => time.to_s("%FT%X%z")}))

      operation.joined_at.value.should eq time
      operation.joined_at.value.not_nil!.utc?.should be_true
    end

    it "gracefully handles bad inputs when parsing" do
      operation = SaveUser.new(Avram::Params.new({
        "joined_at" => "this is not a time",
        "age"       => "not an int",
      }))

      operation.joined_at.errors.should eq ["is invalid"]
      operation.age.errors.should eq ["is invalid"]
      operation.age.value.should be_nil
      operation.joined_at.value.should be_nil
      operation.joined_at.param.should eq "this is not a time"
      operation.age.param.should eq "not an int"
    end
  end

  it "can save empty arrays" do
    bucket = BucketBox.create

    bucket = Bucket::SaveOperation.update!(bucket, names: [] of String)

    bucket.names.should eq([] of String)
  end

  it "set params if passed in" do
    now = Time.utc.at_beginning_of_minute
    user = SaveUser.create!(name: "Dan", age: 34, joined_at: now)
    user.name.should eq "Dan"
    user.age.should eq 34
    user.joined_at.should eq now

    SaveUser.create(name: "Dan", age: 34, joined_at: now) do |_operation, new_user|
      user = new_user.not_nil!
      user.name.should eq "Dan"
      user.age.should eq 34
      user.joined_at.should eq now
    end

    user = UserBox.new.name("New").age(20).joined_at(Time.utc).create
    joined_at = 1.day.ago.at_beginning_of_minute.to_utc
    SaveUser.update(user, name: "New", age: 20, joined_at: joined_at) do |_operation, new_user|
      new_user.name.should eq "New"
      new_user.age.should eq 20
      new_user.joined_at.should eq joined_at
    end

    user = UserBox.new.name("New").age(20).joined_at(Time.utc).create
    user = SaveUser.update!(user, name: "New", age: 20, joined_at: joined_at)
    user.name.should eq "New"
    user.age.should eq 20
    user.joined_at.should eq joined_at
  end

  it "treats nil changes as nil and not an empty string" do
    user = UserBox.build
    operation = SaveUser.new(user)
    operation.name.value = nil

    operation.changes.has_key?(:name).should be_true
    operation.changes[:name].should be_nil
  end

  it "treats empty strings as nil for Time? types instead of failing to parse" do
    avram_params = Avram::Params.new({"title" => "Test", "published_at" => ""})

    post = SavePost.create!(avram_params)

    post.published_at.should eq nil
    post.title.should eq "Test"
  end
end
