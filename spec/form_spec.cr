require "./spec_helper"

private class UserForm < User::BaseForm
  fillable :name, :nickname, :joined_at, :age

  def prepare
    validate_required name, joined_at, age
  end
end

private class LimitedUserForm < User::BaseForm
  fillable :name
end

private class TaskForm < Task::BaseForm
end

private class ValidFormWithoutParams < Post::BaseForm
  def prepare
    title.value = "My Title"
  end
end

private class LineItemForm < LineItem::BaseForm
  fillable :name
end

private class ValueColumnModel < Avram::Model
  table :value_column_model do
    column value : String
  end
end

private class ValueColumnModelForm < ValueColumnModel::BaseForm
  fillable value
end

private class ParamKeyForm < ValueColumnModel::BaseForm
  param_key :custom_param
end

describe "Avram::Form" do
  it "allows overriding the form_name" do
    ParamKeyForm.new.form_name.should eq "custom_param"
    ParamKeyForm.form_name.should eq "custom_param"
  end

  it "generates the correct form_name" do
    LimitedUserForm.new.form_name.should eq "limited_user"
    LimitedUserForm.form_name.should eq "limited_user"
  end

  it "add required_fields method" do
    form = TaskForm.new
    form.required_fields.should eq({form.title})
  end

  it "set params if passed in" do
    now = Time.utc_now.at_beginning_of_minute
    user = UserForm.create!(name: "Dan", age: 34, joined_at: now)
    user.name.should eq "Dan"
    user.age.should eq 34
    user.joined_at.should eq now

    UserForm.create(name: "Dan", age: 34, joined_at: now) do |form, user|
      user = user.not_nil!
      user.name.should eq "Dan"
      user.age.should eq 34
      user.joined_at.should eq now
    end

    user = UserBox.new.name("New").age(20).joined_at(Time.now).create
    joined_at = 1.day.ago.at_beginning_of_minute.to_utc
    UserForm.update(user, name: "New", age: 20, joined_at: joined_at) do |form, user|
      user.name.should eq "New"
      user.age.should eq 20
      user.joined_at.should eq joined_at
    end

    user = UserBox.new.name("New").age(20).joined_at(Time.now).create
    user = UserForm.update!(user, name: "New", age: 20, joined_at: joined_at)
    user.name.should eq "New"
    user.age.should eq 20
    user.joined_at.should eq joined_at
  end

  it "automatically runs validations for required fields" do
    form = TaskForm.new

    form.valid?

    form.valid?.should be_false
    form.title.errors.size.should eq 1
    form.body.errors.size.should eq 0
  end

  it "treats nil changes as nil and not an empty string" do
    form = UserForm.new
    form.name.value = nil

    form.changes.has_key?(:name).should be_true
    form.changes[:name].should be_nil
  end

  describe "#errors" do
    it "includes errors for all form fields" do
      form = UserForm.new

      form.valid?

      form.errors.should eq({
        :name      => ["is required"],
        :age       => ["is required"],
        :joined_at => ["is required"],
      })
    end
  end

  describe "save_failed?" do
    it "is true if the object is invalid and performed an action" do
      params = Avram::Params.new(name: "")
      form = UserForm.new(params)

      form.save

      form.save_failed?.should be_true
      form.save_status.should eq(Avram::Form::SaveStatus::SaveFailed)
      form.valid?.should be_false
    end

    it "is false if the object is not marked as saved but no action was performed" do
      params = Avram::Params.new(name: "")
      form = UserForm.new(params)

      form.save_failed?.should be_false
      form.save_status.should eq(Avram::Form::SaveStatus::Unperformed)
      form.saved?.should be_false
      form.valid?.should be_false
    end
  end

  describe "initializer" do
    it "works with a record and named args" do
      UserBox.new.name("Old Name").create
      params = Avram::Params.new(name: "New Name")
      user = UserQuery.new.first

      form = UserForm.new(user, params)

      form.name.value.should eq "New Name"
    end
  end

  describe "parsing" do
    it "parse integers, time objects, etc." do
      time = 1.day.ago.at_beginning_of_minute
      form = UserForm.new({"joined_at" => time.to_s("%FT%X%z")})

      form.joined_at.value.should eq time
      form.joined_at.value.not_nil!.utc?.should be_true
    end

    it "gracefully handles bad inputs when parsing" do
      form = UserForm.new({
        "joined_at" => "this is not a time",
        "age"       => "not an int",
      })

      form.joined_at.errors.should eq ["is invalid"]
      form.age.errors.should eq ["is invalid"]
      form.age.value.should be_nil
      form.joined_at.value.should be_nil
      form.joined_at.param.should eq "this is not a time"
      form.age.param.should eq "not an int"
    end
  end

  describe "fillable" do
    it "ignores params that are not fillable" do
      form = LimitedUserForm.new({"name" => "someone", "nickname" => "nothing"})
      form.changes.has_key?(:nickname).should be_false
      form.changes[:name]?.should eq "someone"
    end

    it "returns a Avram::FillableField" do
      form = LimitedUserForm.new({"name" => "someone", "nickname" => "nothing"})
      form.nickname.value.should be_nil
      form.nickname.is_a?(Avram::Field).should be_true
      form.name.value.should eq "someone"
      form.name.is_a?(Avram::FillableField).should be_true
    end
  end

  describe "settings values from params" do
    it "sets the values" do
      params = {"name" => "Paul", "nickname" => "Pablito"}

      form = UserForm.new(params)

      form.name.value.should eq "Paul"
      form.nickname.value.should eq "Pablito"
      form.age.value.should eq nil
    end

    it "returns the value from params for updates" do
      user = UserBox.build
      params = {"name" => "New Name From Params"}

      form = UserForm.new(user, params)

      form.name.value.should eq params["name"]
      form.nickname.value.should eq user.nickname
      form.age.value.should eq user.age
    end
  end

  describe "params" do
    it "creates a param method for each of the fillable fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}

      form = UserForm.new(params)

      form.name.param.should eq "Paul"
      form.nickname.param.should eq "Pablito"
    end

    it "uses the value if param is empty" do
      user = UserBox.build

      form = UserForm.new(user, {} of String => String)

      form.name.param.should eq user.name
    end
  end

  describe "errors" do
    it "creates an error method for each of the fillable fields" do
      params = {"name" => "Paul", "age" => "30", "joined_at" => now_as_string}
      form = UserForm.new(params)
      form.valid?.should be_true

      form.name.add_error "is not valid"

      form.valid?.should be_false
      form.name.errors.should eq ["is not valid"]
      form.age.errors.should eq [] of String
    end

    it "only returns unique errors" do
      params = {"name" => "Paul", "nickname" => "Pablito"}
      form = UserForm.new(params)

      form.name.add_error "is not valid"
      form.name.add_error "is not valid"

      form.name.errors.should eq ["is not valid"]
    end
  end

  describe "fields" do
    it "creates a method for each of the fillable fields" do
      params = {} of String => String
      form = LimitedUserForm.new(params)

      form.responds_to?(:name).should be_true
      form.responds_to?(:nickname).should be_true
    end

    it "returns a field with the field name, value and errors" do
      params = {"name" => "Joe"}
      form = UserForm.new(params)
      form.name.add_error "wrong"

      form.name.name.should eq :name
      form.name.value.should eq "Joe"
      form.name.errors.should eq ["wrong"]
    end
  end

  describe ".create" do
    it "can create without params" do
      ValidFormWithoutParams.create do |form, record|
        form.saved?.should be_true
        record.is_a?(Post).should be_true
      end
    end

    it "allows overriding updated_at and created_at on create" do
      user = UserBox.new
        .created_at(Time.new(2018, 1, 1, 10, 20, 30))
        .updated_at(Time.new(2018, 1, 1, 20, 30, 40))
        .create

      user.created_at.should eq Time.new(2018, 1, 1, 10, 20, 30)
      user.updated_at.should eq Time.new(2018, 1, 1, 20, 30, 40)
    end

    context "on success" do
      it "yields the form and the saved record" do
        params = {"joined_at" => now_as_string, "name" => "New Name", "age" => "30"}
        UserForm.create params do |form, record|
          form.saved?.should be_true
          record.is_a?(User).should be_true
        end
      end
    end

    context "on failure" do
      it "yields the form and nil" do
        params = {"name" => "", "age" => "30"}
        UserForm.create params do |form, record|
          form.save_failed?.should be_true
          record.should be_nil
        end
      end

      it "logs the failure if a logger is set" do
        log_io = IO::Memory.new
        logger = Dexter::Logger.new(log_io)
        Avram::Repo.temp_config(logger: logger) do |settings|
          UserForm.create(name: "", age: 30) { |form, record| :unused }
          log_io.to_s.should contain(%("failed_to_save":"UserForm","validation_errors":"name is required. joined_at is required"))
        end
      end
    end

    context "with a uuid backed model" do
      it "can create with params" do
        params = {"name" => "A fancy hat"}
        LineItemForm.create params do |form, record|
          form.saved?.should be_true
          record.should be_a(LineItem)
        end
      end
    end
  end

  describe ".create!" do
    it "can create without params" do
      post = ValidFormWithoutParams.create!
      post.title.should eq("My Title")
    end

    context "on success" do
      it "saves and returns the record" do
        params = {"joined_at" => now_as_string, "name" => "New Name", "age" => "30"}

        record = UserForm.create!(params)

        record.is_a?(User).should be_true
        record.name.should eq "New Name"
      end
    end

    context "on failure" do
      it "raises an exception" do
        params = {"name" => "", "age" => "30"}

        expect_raises Avram::InvalidFormError(UserForm) do
          UserForm.create!(params)
        end
      end
    end

    context "with a uuid backed model" do
      it "can manually set a uuid" do
        LineItemForm.create!(
          id: UUID.new("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"),
          name: "A fancy hat"
        )
        LineItemQuery.new.id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11").select_count.should eq 1
      end
    end

    it "can handle a field named 'value'" do
      ValueColumnModelForm.new({"value" => "value"}).value.value.should eq "value"
    end
  end

  describe "updating with no changes" do
    it "works when there are no changes" do
      UserBox.new.name("Old Name").create
      user = UserQuery.new.first
      params = {} of String => String
      UserForm.update user, with: params do |form, record|
        form.saved?.should be_true
      end
    end

    it "returns true when there are no changes" do
      UserBox.new.name("Old Name").create
      user = UserQuery.new.first
      params = {} of String => String
      UserForm.new(user).tap do |form|
        form.save.should be_true
      end
    end
  end

  describe ".update" do
    it "can create without params" do
      post = PostBox.new.title("Original Title").create
      ValidFormWithoutParams.update(post) do |form, record|
        form.saved?.should be_true
        record.title.should eq "My Title"
      end
    end

    context "on success" do
      it "yields the form and the updated record" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = {"name" => "New Name"}
        UserForm.update user, with: params do |form, record|
          form.saved?.should be_true
          record.name.should eq "New Name"
        end
      end

      it "updates updated_at" do
        user = UserBox.new.updated_at(1.day.ago).create
        params = {"name" => "New Name"}
        UserForm.update user, with: params do |form, record|
          form.saved?.should be_true
          record.updated_at.should be > 1.second.ago
        end
      end
    end

    context "on failure" do
      it "yields the form and nil" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = {"name" => ""}
        UserForm.update user, with: params do |form, record|
          form.save_failed?.should be_true
          record.name.should eq "Old Name"
        end
      end

      it "logs the failure" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        log_io = IO::Memory.new
        logger = Dexter::Logger.new(log_io)
        Avram::Repo.temp_config(logger: logger) do |settings|
          UserForm.update(user, name: "") { |form, record| :unused }
          log_io.to_s.should contain(%("failed_to_save":"UserForm","validation_errors":"name is required"))
        end
      end
    end

    context "with a uuid backed model" do
      it "doesn't generate a new uuid" do
        line_item = LineItemBox.create
        LineItemForm.update(line_item, {"name" => "Another pair of shoes"}) do |form, record|
          form.saved?.should be_true
          record.id.should eq line_item.id
        end
      end
    end
  end

  describe ".update!" do
    it "can create without params" do
      post = PostBox.new.title("Original Title").create
      post = ValidFormWithoutParams.update!(post)
      post.title.should eq "My Title"
    end

    context "on success" do
      it "updates and returns the record" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = {"name" => "New Name"}

        record = UserForm.update! user, with: params

        record.is_a?(User).should be_true
        record.name.should eq "New Name"
      end
    end

    context "on failure" do
      it "raises an exception" do
        UserBox.new.name("Old Name").create
        user = UserQuery.new.first
        params = {"name" => ""}

        expect_raises Avram::InvalidFormError(UserForm) do
          UserForm.update! user, with: params
        end
      end
    end
  end
end

private def now_as_string
  Time.now.to_s("%FT%X%z")
end
