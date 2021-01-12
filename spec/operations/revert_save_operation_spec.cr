require "../spec_helper"

private class SaveUser < User::SaveOperation
  before_save prepare

  def prepare
    validate_required name, joined_at, age
  end
end

private class SaveUserWithNeeds < User::SaveOperation
  needs height : Int32
  needs nice : Bool = true

  before_save prepare

  def prepare
    validate_required name, joined_at, age
  end
end

describe Avram::RevertSaveOperation do
  describe "#revert" do
    context "when operation has no needs" do
      it "deletes new record" do
        operation = SaveUser.new(name: "Dan", age: 34, joined_at: Time.utc)

        operation.revert.valid?.should be_false

        operation.save.should be_true
        UserQuery.new.first?.should_not(be_nil)

        operation.revert.valid?.should be_true
        UserQuery.new.first?.should(be_nil)
      end

      it "reverses updated record" do
        name = "Dan"
        age = 34
        joined = Time.utc(2018, 1, 1, 10, 20, 30)

        new_name = "Mary"
        new_age = 26
        new_joined = Time.utc(2018, 1, 1, 20, 30, 40)

        user = UserBox.create &.name(name).age(age).joined_at(joined)

        operation = SaveUser.new(
          user,
          name: new_name,
          age: new_age,
          joined_at: new_joined
        )

        operation.revert.valid?.should be_false

        operation.save.should be_true

        updated_user = user.reload
        updated_user.name.should eq(new_name)
        updated_user.age.should eq(new_age)
        updated_user.joined_at.should eq(new_joined)

        operation.revert.valid?.should be_true

        reverted_user = user.reload
        reverted_user.name.should eq(name)
        reverted_user.age.should eq(age)
        reverted_user.joined_at.should eq(joined)
      end
    end

    context "when operation has needs" do
      it "deletes new record" do
        operation = SaveUserWithNeeds.new(
          name: "Dan",
          age: 34,
          joined_at: Time.utc,
          nice: true,
          height: 12
        )

        operation.revert.valid?.should be_false

        operation.save.should be_true
        UserQuery.new.first?.should_not(be_nil)

        operation.revert.valid?.should be_true
        UserQuery.new.first?.should(be_nil)
      end

      it "reverses updated record" do
        name = "Dan"
        age = 34
        joined = Time.utc(2018, 1, 1, 10, 20, 30)

        new_name = "Mary"
        new_age = 26
        new_joined = Time.utc(2018, 1, 1, 20, 30, 40)

        user = UserBox.create &.name(name).age(age).joined_at(joined)

        operation = SaveUserWithNeeds.new(
          user,
          name: new_name,
          age: new_age,
          joined_at: new_joined,
          height: 14
        )

        operation.revert.valid?.should be_false

        operation.save.should be_true

        updated_user = user.reload
        updated_user.name.should eq(new_name)
        updated_user.age.should eq(new_age)
        updated_user.joined_at.should eq(new_joined)

        operation.revert.valid?.should be_true

        reverted_user = user.reload
        reverted_user.name.should eq(name)
        reverted_user.age.should eq(age)
        reverted_user.joined_at.should eq(joined)
      end
    end
  end
end
