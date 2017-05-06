require "../spec_helper"

private class UserForm < User::BaseForm
  allow :name, :nickname, :joined_at, :age

  def call
    if name.value.try &.blank?
      name.add_error "is blank"
    end
  end
end

private class LimitedUserForm < User::BaseForm
  allow :name
end

describe "LuckyRecord::Form" do
  describe "save_failed?" do
    it "is false if the object is invalid and performed an action" do
      form = UserForm.new_insert(name: "")

      form.save

      form.save_failed?.should be_true
      form.performed?.should be_true
      form.valid?.should be_false
    end

    it "is true if the object is invalid but no action was performed" do
      form = UserForm.new_insert(name: "")

      form.save_failed?.should be_false
      form.performed?.should be_false
      form.valid?.should be_false
    end
  end

  describe "casting" do
    it "cast integers, time objects, etc." do
      now = Time.now.at_beginning_of_minute
      form = UserForm.new_insert({"joined_at" => now.to_s("%FT%X%z")})

      form.joined_at.value.should eq now
    end

    it "gracefully handles bad inputs when casting" do
      form = UserForm.new_insert({
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

      form = UserForm.new_insert(params)

      form.name.value.should eq "Paul"
      form.nickname.value.should eq "Pablito"
      form.age.value.should eq nil
    end

    it "returns the value from params for updates" do
      user = UserBox.build
      params = {"name" => "New Name From Params"}

      form = UserForm.new_update(to: user, with: params)

      form.name.value.should eq params["name"]
      form.nickname.value.should eq user.nickname
      form.age.value.should eq user.age
    end
  end

  describe "params" do
    it "creates a param method for each of the allowed fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}

      form = UserForm.new_insert(params)

      form.name.param.should eq "Paul"
      form.nickname.param.should eq "Pablito"
    end
  end

  describe "errors" do
    it "creates an error method for each of the allowed fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}
      form = UserForm.new_insert(params)
      form.valid?.should be_true

      form.name.add_error "is not valid"

      form.valid?.should be_false
      form.name.errors.should eq ["is not valid"]
      form.nickname.errors.should eq [] of String
    end

    it "only returns unique errors" do
      params = {"name" => "Paul", "nickname" => "Pablito"}
      form = UserForm.new_insert(params)

      form.name.add_error "is not valid"
      form.name.add_error "is not valid"

      form.name.errors.should eq ["is not valid"]
    end
  end

  describe "fields" do
    it "creates a method for each of the allowed fields" do
      params = {} of String => String
      form = LimitedUserForm.new_insert(params)

      form.responds_to?(:name).should be_true
      form.responds_to?(:nickname).should be_false
    end

    it "returns a field with the field name, value and errors" do
      params = {"name" => "Joe"}
      form = UserForm.new_insert(params)
      form.name.add_error "wrong"

      form.name.name.should eq :name
      form.name.value.should eq "Joe"
      form.name.errors.should eq ["wrong"]
    end
  end

  describe "#new_insert" do
    context "when valid with hash of params" do
      it "casts and inserts into the db, and return true" do
        params = {"name" => "Paul", "age" => "27", "joined_at" => Time.now.to_s("%FT%X%z")}
        form = UserForm.new_insert(params)
        form.performed?.should be_false

        result = form.save

        result.should be_true
        form.performed?.should be_true
        UserRows.new.first.id.should be_truthy
        UserRows.new.first.name.should eq "Paul"
      end
    end

    context "when valid with named tuple" do
      it "casts and inserts into the db, and return true" do
        form = UserForm.new_insert(name: "Paul", age: "27", joined_at: Time.now.to_s("%FT%X%z"))
        form.performed?.should be_false

        result = form.save

        result.should be_true
        form.performed?.should be_true
        UserRows.new.first.id.should be_truthy
      end
    end

    context "invalid" do
      it "does not insert and returns false" do
        params = {"name" => "", "age" => "27", "joined_at" => Time.now.to_s("%FT%X%z")}
        form = UserForm.new_insert(params)
        form.performed?.should be_false

        result = form.save

        result.should be_false
        form.performed?.should be_true
        UserRows.all.to_a.size.should eq 0
      end
    end
  end

  describe "#new_update" do
    context "when valid with hash of params" do
      it "casts and inserts into the db, and return true" do
        create_user(name: "Paul")
        user = UserRows.new.first
        form = UserForm.new_update(user, {"name" => "New Name"})

        result = form.save

        result.should be_true
        form.performed?.should be_true
        UserRows.new.first.name.should eq "New Name"
      end
    end

    context "when valid with named tuple" do
      it "casts and updates the db, and return true" do
        create_user(name: "Paul")
        user = UserRows.new.first
        form = UserForm.new_update(user, name: "New Name")

        result = form.save

        result.should be_true
        form.performed?.should be_true
        UserRows.new.first.name.should eq "New Name"
      end
    end

    context "invalid" do
      it "does not update and returns false" do
        create_user(name: "Old Name")
        user = UserRows.new.first
        form = UserForm.new_update(user, {"name" => ""})

        result = form.save

        result.should be_false
        form.performed?.should be_true
        UserRows.new.first.name.should eq "Old Name"
      end
    end
  end
end

private def create_user(name)
  params = {name: name, age: "27", joined_at: Time.now.to_s("%FT%X%z")}
  UserForm.new_insert(**params).save
end
