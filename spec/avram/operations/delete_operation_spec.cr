require "../../spec_helper"

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

private class DeleteOperationWithAccessToModelValues < Post::DeleteOperation
  before_delete do
    if record.title == "sandbox"
      title.add_error("You can't delete your sandbox")
    end
  end
end

describe "Avram::DeleteOperation" do
  describe "delete" do
    it "deletes the specified record" do
      user = UserFactory.create

      BasicDeleteUser.delete(user) do |operation, deleted_user|
        operation.valid?.should be_true
        operation.delete_status.should eq BasicDeleteUser::OperationStatus::Deleted
        deleted_user.as(User).name.should eq user.name
        UserQuery.new.select_count.should eq 0
      end
    end

    it "does not delete if the operation is invalid" do
      user = UserFactory.create

      FailedToDeleteUser.delete(user) do |operation, deleted_user|
        operation.valid?.should be_false
        operation.delete_status.should eq FailedToDeleteUser::OperationStatus::DeleteFailed
        deleted_user.should be_truthy
        operation.errors[:nope].should contain "not today"
        UserQuery.new.select_count.should eq 1
      end
    end
  end

  describe "delete!" do
    it "deletes the specified record" do
      user = UserFactory.create

      deleted_user = BasicDeleteUser.delete!(user)
      deleted_user.name.should eq user.name
      UserQuery.new.select_count.should eq 0
    end

    it "raises an exception when unable to delete" do
      user = UserFactory.create

      expect_raises(Avram::InvalidOperationError) do
        FailedToDeleteUser.delete!(user)
      end
    end
  end

  describe "soft deletes" do
    it "returns a soft deleted object" do
      item = SoftDeletableItemFactory.create

      deleted_item = SoftDeleteItem.delete!(item)

      deleted_item.soft_deleted?.should be_true
      SoftDeletableItem::BaseQuery.new.find(deleted_item.id).should eq item
    end
  end

  describe "cascade deletes" do
    it "deletes the object and associated" do
      business = BusinessFactory.create
      EmailAddressFactory.create &.business_id(business.id)

      EmailAddress::BaseQuery.new.select_count.should eq(1)

      DeleteWithCascade.delete(business) do |operation, _deleted_business|
        operation.deleted?.should be_true
        EmailAddress::BaseQuery.new.select_count.should eq(0)
      end
    end
  end

  describe "publishes" do
    it "publishes a successful delete" do
      events = [] of Avram::Events::DeleteSuccessEvent
      Avram::Events::DeleteSuccessEvent.subscribe do |event|
        events << event
      end

      user = UserFactory.create

      BasicDeleteUser.delete!(user)
      events.map(&.operation_class).should contain("BasicDeleteUser")
    end

    it "publishes a failed delete" do
      events = [] of Avram::Events::DeleteFailedEvent
      Avram::Events::DeleteFailedEvent.subscribe do |event|
        events << event
      end

      user = UserFactory.create

      expect_raises(Avram::InvalidOperationError) do
        FailedToDeleteUser.delete!(user)
      end

      events.map(&.operation_class).should contain("FailedToDeleteUser")
      events.map(&.error_messages_as_string).should contain("nope not today")

      UserQuery.new.select_count.should eq 1
    end
  end

  context "using the model for conditional deletes" do
    it "adds the error and fails to save" do
      post = PostFactory.create &.title("sandbox")

      DeleteOperationWithAccessToModelValues.delete(post) do |operation, _deleted_post|
        operation.deleted?.should be_false
        operation.errors[:title].should contain("You can't delete your sandbox")
      end
    end
  end
end
