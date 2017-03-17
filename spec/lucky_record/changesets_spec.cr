require "../spec_helper"

class UserChangeset < User::BaseChangeset
  # allow :name, :nickname

  def call
  end
end

describe "LuckyRecord::Changeset" do
  describe "getters" do
    it "creates a getter for all fields" do
      params = {"name" => "Paul", "nickname" => "Pablito"}

      changeset = UserChangeset.new_insert(params)

      changeset.name.should eq "Paul"
      changeset.nickname.should eq "Pablito"
      changeset.age.should eq nil
    end

    it "returns the value from params for updates" do
      user = UserBox.build
      params = {"name" => "New Name From Params"}

      changeset = UserChangeset.new_update(to: user, with: params)

      changeset.name.should eq params["name"]
      changeset.nickname.should eq user.nickname
      changeset.age.should eq user.age
    end
  end
  #
  # describe "params" do
  #   it "creates a param method for each of the allowed fields" do
  #     params = Lucky::Params.new({"first_name" => ["Paul"], "nickname" => ["Smith"]})
  #
  #     changeset = FakeUserChangeset.new(params)
  #
  #     changeset.first_name_param.should eq "Paul"
  #     changeset.last_name_param.should eq "Smith"
  #   end
  # end
  #
  # describe "errors" do
  #   it "creates an error method for each of the allowed fields" do
  #     params = Lucky::Params.new({"first_name" => ["Paul"], "last_name" => ["Smith"]})
  #     changeset = FakeUserChangeset.new(params)
  #
  #     changeset.add_first_name_error "is not valid"
  #
  #     changeset.valid?.should be_false
  #     changeset.first_name_errors.should eq ["is not valid"]
  #     changeset.last_name_errors.should eq [] of String
  #   end
  #
  #   it "returns only adds unique errors" do
  #     params = Lucky::Params.new({"first_name" => ["Paul"]})
  #     changeset = FakeUserChangeset.new(params)
  #
  #     changeset.add_first_name_error "is not valid"
  #     changeset.add_first_name_error "is not valid"
  #
  #     changeset.first_name_errors.should eq ["is not valid"]
  #   end
  # end
  #
  # describe "fields" do
  #   it "creates a field method for each of the allowed fields" do
  #     user = FakeUser.new(first_name: "Old Name", last_name: "Old Last Name")
  #     params = Lucky::Params.new({"first_name" => ["New Name"]})
  #
  #     changeset = FakeUserChangeset.new(user, params)
  #     changeset.add_first_name_error "is not valid"
  #
  #     first_name_field = Lucky::Field.new(
  #       errors: ["is not valid"],
  #       field_name: :first_name,
  #       value: "New Name"
  #     )
  #     changeset.first_name_field.should eq first_name_field
  #     last_name_field = Lucky::Field.new(
  #       errors: [] of String,
  #       field_name: :last_name,
  #       value: "Old Last Name"
  #     )
  #     changeset.last_name_field.should eq last_name_field
  #   end
  # end
  #
  # describe "#new_insert" do
  #   it "inserts if it is valid" do
  #     changeset = UserChangeset.new_insert(name: "Paul", age: 27, joined_at: Time.now)
  #     changeset.performed?.should be_false
  #     changeset.save
  #     changeset.performed?.should be_true
  #   end
  # end

  # describe "#new_update" do
  #   it "updates if it is valid" do
  #     user = UserBox.build
  #     UserChangeset.new_update(update: user, with: {name: "Pablo"}).save
  #   end
  # end
end
