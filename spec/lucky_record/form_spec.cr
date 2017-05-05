require "../spec_helper"

private class UserForm < User::BaseForm
  allow :name, :nickname, :joined_at, :age

  def call
    add_name_error("is blank") if name.try &.blank?
  end
end

private class LimitedUserForm < User::BaseForm
  allow :name
end

describe "LuckyRecord::Form" do
  describe "casting" do
    it "cast integers, time objects, etc." do
      now = Time.now.at_beginning_of_minute
      form = UserForm.new_insert({"joined_at" => now.to_s("%FT%X%z")})

      form.joined_at.should eq now
    end

    it "gracefully handles bad inputs when casting" do
      form = UserForm.new_insert({
        "joined_at" => "this is not a time",
        "age"       => "not an int",
      })

      form.joined_at_errors.should eq ["is invalid"]
      form.age_errors.should eq ["is invalid"]
      form.age.should be_nil
      form.joined_at.should be_nil
      form.joined_at_param.should eq "this is not a time"
      form.age_param.should eq "not an int"
    end
  end

  describe "allow" do
    it "ignores params that are not allowed" do
      form = LimitedUserForm.new({"name" => "someone", "nickname" => "nothing"})
      form.changes.has_key?(:nickname).should be_false
      form.changes[:name]?.should eq "someone"
    end
  end

  describe "getters" do
    it "creates a getter for all fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}

      form = UserForm.new_insert(params)

      form.name.should eq "Paul"
      form.nickname.should eq "Pablito"
      form.age.should eq nil
    end

    it "returns the value from params for updates" do
      user = UserBox.build
      params = {"name" => "New Name From Params"}

      form = UserForm.new_update(to: user, with: params)

      form.name.should eq params["name"]
      form.nickname.should eq user.nickname
      form.age.should eq user.age
    end
  end

  describe "params" do
    it "creates a param method for each of the allowed fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}

      form = UserForm.new_insert(params)

      form.name_param.should eq "Paul"
      form.nickname_param.should eq "Pablito"
    end
  end

  describe "errors" do
    it "creates an error method for each of the allowed fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}
      form = UserForm.new_insert(params)
      form.valid?.should be_true

      form.add_name_error "is not valid"

      form.valid?.should be_false
      form.name_errors.should eq ["is not valid"]
      form.nickname_errors.should eq [] of String
    end

    it "only returns unique errors" do
      params = {"name" => "Paul", "nickname" => "Pablito"}
      form = UserForm.new_insert(params)

      form.add_name_error "is not valid"
      form.add_name_error "is not valid"

      form.name_errors.should eq ["is not valid"]
    end
  end

  describe "fields" do
    it "creates a field method for each of the allowed fields" do
      params = {} of String => String
      form = LimitedUserForm.new_insert(params)

      form.responds_to?(:name_field).should be_true
      form.responds_to?(:nickname_field).should be_false
    end

    it "returns a field with the field name, value and errors" do
      params = {"name" => "Joe"}
      form = UserForm.new_insert(params)
      form.add_name_error "wrong"

      form.name_field.name.should eq :name
      form.name_field.value.should eq "Joe"
      form.name_field.errors.should eq ["wrong"]
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
end
