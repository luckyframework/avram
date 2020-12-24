require "../spec_helper"

private class BasicDeleteUser < User::DeleteOperation
end

private class FailedToDeleteUser < User::DeleteOperation
  before_delete do
    add_error(:nope, "not today")
  end
end

private class SoftDeleteItem < SoftDeletableItem::DeleteOperation
end

private class DeleteWithCascade < Business::DeleteOperation
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

      expect_raises(Avram::InvalidOperationError) do
        FailedToDeleteUser.destroy!(user)
      end
    end
  end

  describe "soft deletes" do
    it "returns a soft deleted object" do
      item = SoftDeletableItemBox.create

      deleted_item = SoftDeleteItem.destroy!(item)

      deleted_item.soft_deleted?.should be_true
    end
  end

  describe "cascade deletes" do
    it "deletes the object and associated" do
      business = BusinessBox.create
      email_address = EmailAddressBox.create &.business_id(business.id)

      EmailAddress::BaseQuery.new.select_count.should eq(1)

      DeleteWithCascade.destroy(business) do |operation, _deleted_business|
        operation.deleted?.should be_true
        EmailAddress::BaseQuery.new.select_count.should eq(0)
      end
    end
  end

  describe "publishes" do
    it "publishes a successful delete" do
      Avram::Events::DeleteSuccessEvent.subscribe do |event|
        if event.operation_class == "BasicDeleteUser"
          UserQuery.new.select_count.should eq 0
        end
      end

      user = UserBox.create

      BasicDeleteUser.destroy!(user)
    end

    it "publishes a failed delete" do
      Avram::Events::DeleteFailedEvent.subscribe do |event|
        event.operation_class.should eq("FailedToDeleteUser")
        event.error_messages_as_string.should contain("not today")
        UserQuery.new.select_count.should eq 1
      end

      user = UserBox.create

      expect_raises(Avram::InvalidOperationError) do
        FailedToDeleteUser.destroy!(user)
      end
    end
  end
end
