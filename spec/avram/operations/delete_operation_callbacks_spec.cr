require "../../spec_helper"

module TestableOperation
  macro included
    @callbacks_that_ran = [] of String
    getter callbacks_that_ran

    def mark_callback(callback_name : String)
      @callbacks_that_ran << callback_name
    end
  end
end

private class DeleteOperationWithCallbacks < User::DeleteOperation
  include TestableOperation

  before_delete :update_number
  before_delete { mark_callback("before_delete_in_a_block") }

  after_delete :notify_complete
  after_delete do |deleted_user|
    mark_callback("after_delete_in_a_block with #{deleted_user.name}")
  end

  private def update_number
    mark_callback("before_delete_update_number")
  end

  private def notify_complete(deleted_user)
    mark_callback("after_delete_notify_complete is #{deleted_user.name}")
  end
end

describe "Avram::DeleteOperation callbacks" do
  it "runs before_delete and after_delete callbacks" do
    user = UserFactory.create &.name("Jerry")

    DeleteOperationWithCallbacks.delete(user) do |operation, deleted_user|
      deleted_user.as(User).name.should eq "Jerry"
      operation.callbacks_that_ran.should contain "before_delete_update_number"
      operation.callbacks_that_ran.should contain "before_delete_in_a_block"
      operation.callbacks_that_ran.should contain "after_delete_notify_complete is Jerry"
      operation.callbacks_that_ran.should contain "after_delete_in_a_block with Jerry"
    end
  end
end
