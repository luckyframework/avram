require "../../spec_helper"

include ParamHelper

private class SaveUser < User::SaveOperation
  # There was a bug where adding a non-database attribute would make it so
  # 'attributes' only returned the non-database attributes.
  #
  # So we add a non-database attribute and check that the permitted_columns are
  # still included in validation errors.
  attribute should_not_override_permitted_columns : String
  permit_columns :name, :nickname, :joined_at, :age
  attribute set_from_init : String
  before_save prepare

  def prepare
    validate_required name, joined_at, age
  end
end

private class RenameUser < SaveUser
  # This catches a compile-time bug when inheriting
  # from a SaveOperation that has attributes and permitted columns
  before_save do
    nickname.value = "The '#{nickname.value}'"
  end
end

private class SaveUserWithFalseValueValidations < User::SaveOperation
  param_key :false_val
  permit_columns :nickname, :available_for_hire

  before_save do
    validate_required nickname, available_for_hire
  end
end

private class SaveLimitedUser < User::SaveOperation
  permit_columns :name
end

private class SaveTask < Task::SaveOperation
  permit_columns :completed_at
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

private class ValueColumnModel < BaseModel
  table :value_column_model do
    column value : String
  end
end

private class ValueColumnModelSaveOperation < ValueColumnModel::SaveOperation
  permit_columns value
  param_key :val_col
end

private class ParamKeySaveOperation < ValueColumnModel::SaveOperation
  param_key :custom_param
end

private class UpsertUserOperation < User::SaveOperation
  upsert_lookup_columns :name, :nickname
end

private class OverrideDefaults < ModelWithDefaultValues::SaveOperation
  permit_columns :greeting, :drafted_at, :published_at, :admin, :age, :money
end

private class SavePost < Post::SaveOperation
  permit_columns :title, :published_at
end

# This is to test an escape hatch where you don't want to
# define a Nil type, but your field is optional
private class AllowBlankComment < Comment::SaveOperation
  skip_default_validations

  before_save do
    body.allow_blank = true
  end
end

module DefaultUserValidations
  macro included
    property starts_nil : String? = nil

    default_validations do
      self.starts_nil = self.starts_nil.to_s + "!"
      validate_required nickname
    end
  end
end

private class UserWithDefaultValidations < User::SaveOperation
  include DefaultUserValidations

  before_save do
    self.starts_nil = "not nil"
  end
end

describe "Avram::SaveOperation" do
  it "calls the default validations after the before_save" do
    UserWithDefaultValidations.create(name: "TestName", nickname: "TestNickname", joined_at: Time.utc, age: 400) do |op, u|
      op.starts_nil.should eq("not nil!")
      u.should_not be_nil
      u.as(User).nickname.should eq("TestNickname")
    end
  end

  it "allows overriding the param_key" do
    ParamKeySaveOperation.param_key.should eq "custom_param"
  end

  it "generates the correct param_key based on the model class" do
    SaveLimitedUser.param_key.should eq "user"
  end

  it "add required_attributes method" do
    operation = SaveTask.new
    operation.required_attributes.should eq({operation.title})
  end

  it "can save empty arrays" do
    bucket = BucketFactory.create

    bucket = Bucket::SaveOperation.update!(bucket, names: [] of String)

    bucket.names.should eq([] of String)
  end

  it "treats empty strings as nil for Time? types instead of failing to parse" do
    params = build_params("post:title=Test&post:published_at=")
    post = SavePost.create!(params)

    post.published_at.should eq nil
    post.title.should eq "Test"
  end

  describe ".create" do
    it "sets params if passed in" do
      now = Time.utc.at_beginning_of_minute
      user = SaveUser.create!(name: "Dan", age: 34, joined_at: now)
      user.name.should eq "Dan"
      user.age.should eq 34
      user.joined_at.should eq now
    end

    it "passes params to the block" do
      now = Time.utc.at_beginning_of_minute
      SaveUser.create(name: "Dan", age: 34, joined_at: now) do |_operation, user|
        user = user.as(User)
        user.name.should eq "Dan"
        user.age.should eq 34
        user.joined_at.should eq now
      end
    end
  end

  describe ".update" do
    it "sets params if passed it" do
      joined_at = 1.day.ago.at_beginning_of_minute.to_utc
      user = UserFactory.new.name("New").age(20).joined_at(Time.utc).create
      user = SaveUser.update!(user, name: "New", age: 20, joined_at: joined_at)
      user.name.should eq "New"
      user.age.should eq 20
      user.joined_at.should eq joined_at
    end

    it "passes params to the block" do
      user_factory = UserFactory.new.name("New").age(20).joined_at(Time.utc).create
      joined_at = 1.day.ago.at_beginning_of_minute.to_utc

      SaveUser.update(user_factory, name: "New", age: 20, joined_at: joined_at) do |_operation, user|
        user.name.should eq "New"
        user.age.should eq 20
        user.joined_at.should eq joined_at
      end
    end
  end

  it "automatically runs validations for required attributes" do
    operation = SaveTask.new

    operation.valid?

    operation.valid?.should be_false
    operation.title.errors.size.should eq 1
    operation.body.errors.size.should eq 0
  end

  it "treats nil changes as nil and not an empty string" do
    user = UserFactory.build
    operation = SaveUser.new(user)
    operation.name.value = nil

    operation.changes.has_key?(:name).should be_true
    operation.changes[:name].should be_nil
  end

  describe "upsert upsert_lookup_columns" do
    describe ".upsert" do
      it "updates the existing record if one exists" do
        existing_user = UserFactory.create &.name("Rich").nickname(nil).age(20)
        joined_at = Time.utc.at_beginning_of_second

        UpsertUserOperation.upsert(
          name: "Rich",
          nickname: nil,
          age: 30,
          joined_at: joined_at
        ) do |operation, user|
          operation.created?.should be_false
          operation.updated?.should be_true
          UserQuery.new.select_count.should eq(1)
          user = user.as(User)
          user.id.should eq(existing_user.id)
          user.name.should eq("Rich")
          user.nickname.should be_nil
          user.age.should eq(30)
          user.joined_at.should eq(joined_at)
        end
      end

      it "creates a new record if match one doesn't exist" do
        user_with_different_nickname =
          UserFactory.create &.name("Rich").nickname(nil).age(20)
        joined_at = Time.utc.at_beginning_of_second

        UpsertUserOperation.upsert(
          name: "Rich",
          nickname: "R.",
          age: 30,
          joined_at: joined_at
        ) do |operation, user|
          operation.created?.should be_true
          operation.updated?.should be_false
          UserQuery.new.select_count.should eq(2)
          # Keep existing user the same
          user_with_different_nickname.age.should eq(20)
          user_with_different_nickname.nickname.should eq(nil)

          user = user.as(User)
          user.id.should_not eq(user_with_different_nickname.id)
          user.name.should eq("Rich")
          user.nickname.should eq("R.")
          user.age.should eq(30)
          user.joined_at.should eq(joined_at)
        end
      end
    end

    describe ".upsert!" do
      it "updates the existing record if one exists" do
        existing_user = UserFactory.create &.name("Rich").nickname(nil).age(20)
        joined_at = Time.utc.at_beginning_of_second

        user = UpsertUserOperation.upsert!(
          name: "Rich",
          nickname: nil,
          age: 30,
          joined_at: joined_at
        )

        UserQuery.new.select_count.should eq(1)
        user = user.as(User)
        user.id.should eq(existing_user.id)
        user.name.should eq("Rich")
        user.nickname.should be_nil
        user.age.should eq(30)
        user.joined_at.should eq(joined_at)
      end

      it "creates a new record if one doesn't exist" do
        user_with_different_nickname = UserFactory.create &.name("Rich").nickname(nil).age(20)
        joined_at = Time.utc.at_beginning_of_second

        user = UpsertUserOperation.upsert!(
          name: "Rich",
          nickname: "R.",
          age: 30,
          joined_at: joined_at
        )

        UserQuery.new.select_count.should eq(2)
        # Keep existing user the same
        user_with_different_nickname.age.should eq(20)
        user_with_different_nickname.nickname.should eq(nil)

        user = user.as(User)
        user.id.should_not eq(user_with_different_nickname.id)
        user.name.should eq("Rich")
        user.nickname.should eq("R.")
        user.age.should eq(30)
        user.joined_at.should eq(joined_at)
      end

      it "raises if the record is invalid" do
        expect_raises(Avram::InvalidOperationError) do
          UpsertUserOperation.upsert!(name: "")
        end
      end
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
  end

  describe "save_failed?" do
    it "is true if the object is invalid and performed an action" do
      operation = SaveUser.new(name: "")

      operation.save

      operation.save_failed?.should be_true
      operation.save_status.should eq(SaveUser::OperationStatus::SaveFailed)
      operation.valid?.should be_false
      operation.created?.should be_false
      operation.updated?.should be_false
    end

    it "is false if the object is not marked as saved but no action was performed" do
      operation = SaveUser.new(name: "")

      operation.save_failed?.should be_false
      operation.save_status.should eq(SaveUser::OperationStatus::Unperformed)
      operation.saved?.should be_false
      operation.valid?.should be_false
      operation.created?.should be_false
      operation.updated?.should be_false
    end
  end

  describe "initializer" do
    it "works with a record and named args" do
      UserFactory.new.name("Old Name").create
      params = build_params("user:name=New Name")
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

  describe "parsing" do
    it "parse integers, time objects, etc." do
      time = 1.day.ago.at_beginning_of_minute
      params = build_params("user:joined_at=#{time.to_s("%FT%X%z")}")
      operation = SaveUser.new(params)

      operation.joined_at.value.should eq time
      operation.joined_at.value.as(Time).utc?.should be_true
    end

    it "gracefully handles bad inputs when parsing" do
      params = build_params("user:joined_at=this is not a time&user:age=not an int")
      operation = SaveUser.new(params)

      operation.joined_at.errors.should eq ["is invalid"]
      operation.age.errors.should eq ["is invalid"]
      operation.age.value.should be_nil
      operation.joined_at.value.should be_nil
      operation.joined_at.param.should eq "this is not a time"
      operation.age.param.should eq "not an int"
    end
  end

  describe "permit_columns" do
    it "ignores params that are not permitted" do
      params = build_params("user:name=someone&user:nickname=nothing")
      operation = SaveLimitedUser.new(params)
      operation.changes.has_key?(:nickname).should be_false
      operation.changes[:name]?.should eq "someone"
    end

    it "returns a Avram::PermittedAttribute" do
      params = build_params("user:name=someone&user:nickname=nothing")
      operation = SaveLimitedUser.new(params)
      operation.nickname.value.should be_nil
      operation.nickname.is_a?(Avram::Attribute).should be_true
      operation.name.value.should eq "someone"
      operation.name.is_a?(Avram::PermittedAttribute).should be_true
    end
  end

  describe "settings values from params" do
    it "sets the values" do
      params = build_params("user:name=Paul&user:nickname=Pablito")

      operation = SaveUser.new(params)

      operation.name.value.should eq "Paul"
      operation.nickname.value.should eq "Pablito"
      operation.age.value.should eq nil
    end

    it "returns the value from params for updates" do
      user = UserFactory.build
      params = build_params("user:name=New+Name+From+Params")

      operation = SaveUser.new(user, params)

      operation.name.value.should eq "New Name From Params"
      operation.nickname.value.should eq user.nickname
      operation.age.value.should eq user.age
    end
  end

  describe "params" do
    it "creates a param method for each of the permit_columns attributes" do
      params = build_params("user:name=Paul&user:nickname=Pablito")

      operation = SaveUser.new(params)

      operation.name.param.should eq "Paul"
      operation.nickname.param.should eq "Pablito"
    end

    it "uses the value if param is empty" do
      user = UserFactory.build

      operation = SaveUser.new(user)

      operation.name.param.should eq user.name
    end

    it "raises an exception when you pass empty params" do
      user = UserFactory.build

      params = build_params("")
      expect_raises(Exception) do
        SaveUser.new(user, params)
      end
    end
  end

  describe "errors" do
    it "creates an error method for each of the permit_columns attributes" do
      params = build_params("user:name=Paul&user:age=30&user:joined_at=#{now_as_string}")
      operation = SaveUser.new(params)
      operation.valid?.should be_true

      operation.name.add_error "is not valid"

      operation.valid?.should be_false
      operation.name.errors.should eq ["is not valid"]
      operation.age.errors.should eq [] of String
    end

    it "only returns unique errors" do
      params = build_params("user:name=Paul&user:nickname=Pablito")
      operation = SaveUser.new(params)

      operation.name.add_error "is not valid"
      operation.name.add_error "is not valid"

      operation.name.errors.should eq ["is not valid"]
    end
  end

  describe "attributes" do
    it "creates a method for each of the permit_columns attributes" do
      operation = SaveLimitedUser.new

      operation.responds_to?(:name).should be_true
      operation.responds_to?(:nickname).should be_true
    end

    it "returns an attribute with the attribute name, value and errors" do
      params = build_params("user:name=Joe")
      operation = SaveUser.new(params)
      operation.name.add_error "wrong"

      operation.name.name.should eq :name
      operation.name.value.should eq "Joe"
      operation.name.errors.should eq ["wrong"]
    end

    it "has inherited attributes" do
      user = UserFactory.create &.nickname("taco shop")

      RenameUser.update(user, should_not_override_permitted_columns: "yo") do |op, u|
        u.nickname.should eq("The 'taco shop'")
        op.should_not_override_permitted_columns.value.should eq("yo")
      end
    end
  end

  describe ".create" do
    it "can create without params" do
      ValidSaveOperationWithoutParams.create do |operation, record|
        operation.saved?.should be_true
        record.is_a?(Post).should be_true
      end
    end

    it "allows overriding updated_at and created_at on create" do
      user = UserFactory.new
        .created_at(Time.utc(2018, 1, 1, 10, 20, 30))
        .updated_at(Time.utc(2018, 1, 1, 20, 30, 40))
        .create

      user.created_at.should eq Time.utc(2018, 1, 1, 10, 20, 30)
      user.updated_at.should eq Time.utc(2018, 1, 1, 20, 30, 40)
    end

    context "on success" do
      it "yields the operation and the saved record" do
        params = build_params("user:joined_at=#{now_as_string}&user:name=New Name&user:age=30")
        SaveUser.create params do |operation, record|
          operation.saved?.should be_true
          record.is_a?(User).should be_true
        end
      end
    end

    context "on failure" do
      it "yields the operation and nil" do
        params = build_params("user:name=&user:age=30")
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
        params = build_params("line_item:name=A fancy hat")
        SaveLineItem.create params do |operation, record|
          operation.saved?.should be_true
          record.should be_a(LineItem)
        end
      end
    end

    context "when there's default values in the table" do
      it "saves with all of the default values" do
        ModelWithDefaultValues::SaveOperation.create do |_operation, record|
          record.should_not eq nil
          r = record.as(ModelWithDefaultValues)
          r.greeting.should eq "Hello there!"
          r.admin.should eq false
          r.age.should eq 30
          r.money.should eq 3.5
          r.published_at.should be_a Time
          r.drafted_at.should be_a Time
        end
      end

      it "allows you to override the default values" do
        ModelWithDefaultValues::SaveOperation.create(greeting: "A fancy hat") do |_operation, record|
          record.should_not eq nil
          r = record.as(ModelWithDefaultValues)
          r.greeting.should eq "A fancy hat"
          r.admin.should eq false
          r.age.should eq 30
          r.money.should eq 3.5
          r.published_at.should be_a Time
          r.drafted_at.should be_a Time
        end
      end

      it "allows supplying a value that matches the default" do
        result = Company::SaveOperation.create!(sales: 0_i64, earnings: 0_f64)
        default_result = Company::SaveOperation.create!

        result.sales.should eq default_result.sales
        result.earnings.should eq default_result.earnings
      end

      it "overrides all of the defaults through params" do
        published_at = 1.day.ago.to_utc.at_beginning_of_day
        drafted_at = 1.week.ago.to_utc.at_beginning_of_day
        params = build_params("model_with_default_values:greeting=Hi&model_with_default_values:admin=true&model_with_default_values:age=4&model_with_default_values:money=100.23&model_with_default_values:published_at=#{published_at}&model_with_default_values:drafted_at=#{drafted_at}")
        OverrideDefaults.create(params) do |_operation, record|
          record.should_not eq nil
          r = record.as(ModelWithDefaultValues)
          r.greeting.should eq "Hi"
          r.admin.should eq true
          r.age.should eq 4
          r.money.should eq 100.23
          r.published_at.should eq published_at
          r.drafted_at.should eq drafted_at
        end
      end

      it "updates with a record that has defaults" do
        model = ModelWithDefaultValues::SaveOperation.create!
        record = OverrideDefaults.update!(model, greeting: "Hi")
        record.greeting.should eq "Hi"
        record.admin.should eq false
      end

      it "lets named args take precedence over param values" do
        params = build_params("model_with_default_values:greeting=Hi")
        OverrideDefaults.create(params, greeting: "sup") do |_operation, record|
          record.should_not eq nil
          r = record.as(ModelWithDefaultValues)
          r.greeting.should eq "sup"
        end

        model = ModelWithDefaultValues::SaveOperation.create!
        model.greeting.should eq("Hello there!")

        params = build_params("model_with_default_values:greeting=Hi")
        OverrideDefaults.update(model, params, greeting: "General Kenobi") do |_operation, record|
          record.should_not eq nil
          r = record.as(ModelWithDefaultValues)
          r.greeting.should eq "General Kenobi"
        end
      end
    end

    context "with bytes" do
      it "saves the byte column" do
        Beat::SaveOperation.create(hash: "boots and pants".to_slice) do |op, beat|
          op.saved?.should eq(true)
          beat.should_not be_nil
          beat.as(Beat).hash.blank?.should eq(false)
          beat.as(Beat).hash.should eq(Bytes[98, 111, 111, 116, 115, 32, 97, 110, 100, 32, 112, 97, 110, 116, 115])
          String.new(beat.as(Beat).hash).should eq("boots and pants")
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
        params = build_params("user:joined_at=#{now_as_string}&user:name=New Name&user:age=30")

        record = SaveUser.create!(params)

        record.is_a?(User).should be_true
        record.name.should eq "New Name"
      end
    end

    context "on failure" do
      it "raises an exception" do
        params = build_params("user:name=&user:age=30")

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
      params = build_params("val_col:value=value")
      ValueColumnModelSaveOperation.new(params).value.value.should eq "value"
    end
  end

  describe "updating with no changes" do
    it "works when there are no changes" do
      UserFactory.new.name("Old Name").create
      user = UserQuery.new.first

      SaveUser.update(user) do |operation, _record|
        operation.saved?.should be_true
      end
    end

    it "returns true when there are no changes" do
      UserFactory.new.name("Old Name").create
      user = UserQuery.new.first
      SaveUser.new(user).tap do |operation|
        operation.save.should be_true
      end
    end
  end

  describe ".update" do
    it "can create without params" do
      post = PostFactory.new.title("Original Title").create
      ValidSaveOperationWithoutParams.update(post) do |operation, record|
        operation.saved?.should be_true
        record.title.should eq "My Title"
      end
    end

    context "on success" do
      it "yields the operation and the updated record" do
        UserFactory.new.name("Old Name").create
        user = UserQuery.new.first
        params = build_params("user:name=New Name")
        SaveUser.update user, with: params do |operation, record|
          operation.saved?.should be_true
          record.name.should eq "New Name"
        end
      end

      it "updates updated_at" do
        user = UserFactory.new.updated_at(1.day.ago).create
        params = build_params("user:name=New Name")
        SaveUser.update user, with: params do |operation, record|
          operation.saved?.should be_true
          record.updated_at.should be > 1.second.ago
        end
      end
    end

    context "on failure" do
      it "yields the operation and nil" do
        UserFactory.new.name("Old Name").create
        user = UserQuery.new.first
        params = build_params("user:name=")
        SaveUser.update user, with: params do |operation, record|
          operation.save_failed?.should be_true
          record.name.should eq "Old Name"
        end
      end

      it "logs the failure" do
        UserFactory.new.name("Old Name").create
        user = UserQuery.new.first

        Avram::SaveFailedLog.dexter.temp_config do |log_io|
          SaveUser.update(user, name: "") { |_operation, _record| :unused }
          log_io.to_s.should contain(%("failed_to_save" => "SaveUser", "validation_errors" => "name is required"))
        end
      end
    end

    context "with a uuid backed model" do
      it "doesn't generate a new uuid" do
        line_item = LineItemFactory.create
        params = build_params("line_item:name=Another pair of shoes")
        SaveLineItem.update(line_item, params) do |operation, record|
          operation.saved?.should be_true
          record.id.should eq line_item.id
        end
      end
    end

    context "when the default is false and the field is required" do
      it "is valid since 'false' is a valid Boolean value" do
        user = UserFactory.create &.nickname("oopsie").available_for_hire(false)
        params = build_params("false_val:nickname=falsey mcfalserson")
        SaveUserWithFalseValueValidations.update(user, params) do |operation, record|
          record.should_not eq nil
          r = record.as(User)
          operation.valid?.should be_true
          r.nickname.should eq "falsey mcfalserson"
          r.available_for_hire.should eq false
        end
      end
    end
  end

  describe ".update!" do
    it "can create without params" do
      post = PostFactory.new.title("Original Title").create
      post = ValidSaveOperationWithoutParams.update!(post)
      post.title.should eq "My Title"
    end

    it "updates a value back to nil" do
      task = TaskFactory.new.title("Welcome").body("To the jungle").completed_at(1.day.ago).create
      params = build_params(%({"task": {"completed_at": null}}), content_type: "application/json")

      updated_task = SaveTask.update!(task, params)
      updated_task.body.should eq("To the jungle")
      updated_task.completed_at.should eq(nil)
    end

    context "on success" do
      it "updates and returns the record" do
        UserFactory.new.name("Old Name").create
        user = UserQuery.new.first
        params = build_params("user:name=New Name")

        record = SaveUser.update! user, with: params

        record.is_a?(User).should be_true
        record.name.should eq "New Name"
      end
    end

    context "on failure" do
      it "raises an exception" do
        UserFactory.new.name("Old Name").create
        user = UserQuery.new.first
        params = build_params("user:name=")

        expect_raises Avram::InvalidOperationError do
          SaveUser.update! user, with: params
        end
      end
    end
  end

  describe "#new_record?" do
    context "when creating" do
      it "returns 'true'" do
        operation = SaveUser.new(name: "Dan", age: 34, joined_at: Time.utc)

        operation.new_record?.should be_true
        operation.save.should be_true
        operation.new_record?.should be_true
      end
    end

    context "when updating" do
      it "returns 'false'" do
        user = UserFactory.create &.name("Dan").age(34).joined_at(Time.utc)
        operation = SaveUser.new(user, name: "Tom")

        operation.new_record?.should be_false
        operation.save.should be_true
        operation.new_record?.should be_false
      end
    end
  end

  describe "#created?" do
    context "after creating" do
      it "returns 'true'" do
        operation = SaveUser.new(name: "Dan", age: 34, joined_at: Time.utc)

        operation.created?.should be_false
        operation.save.should be_true
        operation.created?.should be_true
      end
    end

    context "after updating" do
      it "returns 'false'" do
        user = UserFactory.create &.name("Dan").age(34).joined_at(Time.utc)
        operation = SaveUser.new(user, name: "Tom")

        operation.created?.should be_false
        operation.save.should be_true
        operation.created?.should be_false
      end
    end
  end

  describe "#updated?" do
    context "after creating" do
      it "returns 'false'" do
        operation = SaveUser.new(name: "Dan", age: 34, joined_at: Time.utc)

        operation.updated?.should be_false
        operation.save.should be_true
        operation.updated?.should be_false
      end
    end

    context "after updating" do
      it "returns 'true'" do
        user = UserFactory.create &.name("Dan").age(34).joined_at(Time.utc)
        operation = SaveUser.new(user, name: "Tom")

        operation.updated?.should be_false
        operation.save.should be_true
        operation.updated?.should be_true
      end
    end
  end

  describe "skip_default_validations" do
    it "allows blank strings to be saved" do
      post = PostFactory.create
      AllowBlankComment.create(post_id: post.id, body: "") do |op, new_comment|
        op.valid?.should be_true
        comment = new_comment.as(Comment)
        comment.body.should eq("")
      end
    end
    it "still allows normal data to be saved" do
      post = PostFactory.create
      AllowBlankComment.create(post_id: post.id, body: "not blank") do |op, new_comment|
        op.valid?.should be_true
        comment = new_comment.as(Comment)
        comment.body.should eq("not blank")
      end
    end
    it "fails at postgres when saving nil" do
      post = PostFactory.create
      expect_raises(PQ::PQError) do
        AllowBlankComment.create(post_id: post.id) do |_op, _new_comment|
        end
      end
    end
  end
end

private def now_as_string
  Time.utc.to_s("%FT%X%z")
end
