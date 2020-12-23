require "../spec_helper"

private class BasicDeleteUser < User::DeleteOperation
end

private class FailedToDeleteUser < User::DeleteOperation
  before_delete do
    add_error(:nope, "not today")
  end
end

describe "Avram::DeleteOperation" do

  describe "destroy" do
    it "deletes the specified record" do
      user = UserBox.create

      BasicDeleteUser.destroy(user) do |operation, deleted_user|
        operation.valid?.should be_true
        operation.delete_status.should eq BasicDeleteUser::DeleteStatus::Deleted
        deleted_user.not_nil!.name.should eq user.name
        UserQuery.new.select_count.should eq 0
      end
    end

    it "fails to delete the specified record" do
      user = UserBox.create

      FailedToDeleteUser.destroy(user) do |operation, deleted_user|
        operation.valid?.should be_false
        operation.delete_status.should eq FailedToDeleteUser::DeleteStatus::DeleteFailed
        deleted_user.should eq nil
        operation.errors[:nope].should contain "not today"
        UserQuery.new.select_count.should eq 1
      end
    end
  end

  describe "destroy!" do
    it "deletes the specified record" do
      user = UserBox.create

      deleted_user = BasicDeleteUser.destroy!(user)
      deleted_user.name.should eq user.name
      UserQuery.new.select_count.should eq 0
    end

    it "raises an exception when unable to delete" do
      user = UserBox.create

      expect_raises(Avram::InvalidOperationError, ) do
        FailedToDeleteUser.destroy!(user)
      end
    end
  end
end
