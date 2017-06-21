require "./spec_helper"

private class UserForm < User::BaseForm
  allow :name, :nickname, :joined_at, :age

  def call
    validate_required name, joined_at, age
  end

  private def validate_required(*fields)
    fields.each do |field|
      if field.value.blank?
        field.add_error "is blank"
      end
    end
  end
end

private class LimitedUserForm < User::BaseForm
  allow :name
end

describe "LuckyRecord::Form" do
  describe "save_failed?" do
    it "is false if the object is invalid and performed an action" do
      form = UserForm.new(name: "")

      form.save

      form.save_failed?.should be_true
      form.performed?.should be_true
      form.valid?.should be_false
    end

    it "is true if the object is invalid but no action was performed" do
      form = UserForm.new(name: "")

      form.save_failed?.should be_false
      form.performed?.should be_false
      form.valid?.should be_false
    end
  end

  describe "casting" do
    it "cast integers, time objects, etc." do
      now = Time.now.at_beginning_of_minute
      form = UserForm.new({"joined_at" => now.to_s("%FT%X%z")})

      form.joined_at.value.should eq now
    end

    it "gracefully handles bad inputs when casting" do
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

  describe "allow" do
    it "ignores params that are not allowed" do
      form = LimitedUserForm.new({"name" => "someone", "nickname" => "nothing"})
      form.changes.has_key?(:nickname).should be_false
      form.changes[:name]?.should eq "someone"
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
    it "creates a param method for each of the allowed fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}

      form = UserForm.new(params)

      form.name.param.should eq "Paul"
      form.nickname.param.should eq "Pablito"
    end
  end

  describe "errors" do
    it "creates an error method for each of the allowed fields" do
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
    it "creates a method for each of the allowed fields" do
      params = {} of String => String
      form = LimitedUserForm.new(params)

      form.responds_to?(:name).should be_true
      form.responds_to?(:nickname).should be_false
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

  describe ".save" do
    context "on success" do
      it "yields the form and the saved record" do
        params = {"joined_at" => now_as_string, "name" => "New Name", "age" => "30"}
        UserForm.save params do |form, record|
          form.save_succeeded?.should be_true
          record.is_a?(User).should be_true
        end
      end
    end

    context "on failure" do
      it "yields the form and nil" do
        params = {"name" => "", "age" => "30"}
        UserForm.save params do |form, record|
          form.save_failed?.should be_true
          record.should be_nil
        end
      end
    end
  end

  describe ".update" do
    context "on success" do
      it "yields the form and the updated record" do
        create_user(name: "Old Name")
        user = UserQuery.new.first
        params = {"name" => "New Name"}
        UserForm.update user, with: params do |form, record|
          form.save_succeeded?.should be_true
          record.name.should eq "New Name"
        end
      end
    end

    context "on failure" do
      it "yields the form and nil" do
        create_user(name: "Old Name")
        user = UserQuery.new.first
        params = {"name" => ""}
        UserForm.update user, with: params do |form, record|
          form.save_failed?.should be_true
          record.name.should eq "Old Name"
        end
      end
    end
  end
end

private def create_user(name)
  params = {name: name, age: "27", joined_at: now_as_string}
  UserForm.new(**params).save
end

private def now_as_string
  Time.now.to_s("%FT%X%z")
end
