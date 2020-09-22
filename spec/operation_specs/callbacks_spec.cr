require "../spec_helper"

module TestableOperation
  macro included
    @callbacks_that_ran = [] of String
    getter callbacks_that_ran

    def mark_callback(callback_name : String)
      @callbacks_that_ran << callback_name
    end
  end
end

private class OperationWithCallbacks < Avram::Operation
  include TestableOperation
  attribute number : Int32 = 1

  before_run :update_number
  before_run { mark_callback("before_run_in_a_block") }

  after_run :notify_complete
  after_run do |return_value_of_run_method|
    mark_callback("after_run_in_a_block with #{return_value_of_run_method}")
  end

  def run
    number.value
  end

  private def update_number
    mark_callback("before_run_update_number")
    number.value = 4
  end

  private def notify_complete(return_value_of_run_method)
    mark_callback("after_run_notify_complete is #{return_value_of_run_method}")
  end
end

private class SaveOperationWithCallbacks < Post::SaveOperation
  include TestableOperation

  before_save :set_title
  before_save { mark_callback("before_save_in_a_block") }

  after_save :notify_save_complete
  after_save do |saved_post|
    mark_callback("after_save_in_a_block with #{saved_post.title}")
  end

  after_commit :notify_commit_complete
  after_commit do |saved_post|
    mark_callback("after_commit_in_a_block with #{saved_post.title}")
  end

  private def set_title
    mark_callback("before_save_update_title")
    title.value = "Saved Post"
  end

  private def notify_save_complete(saved_post)
    mark_callback("after_save_notify_save_complete with #{saved_post.title}")
  end

  private def notify_commit_complete(saved_post)
    mark_callback("after_commit_notify_commit_complete with #{saved_post.title}")
  end
end

describe "Avram::Callbacks" do
  describe "Avram::Operation" do
    it "runs before_run and after_run callbacks" do
      OperationWithCallbacks.run do |operation, value|
        operation.callbacks_that_ran.should contain "before_run_update_number"
        operation.callbacks_that_ran.should contain "before_run_in_a_block"
        value.should eq 4
        operation.number.value.should eq 4
        operation.number.original_value.should eq 1
        operation.callbacks_that_ran.should contain "after_run_notify_complete is 4"
        operation.callbacks_that_ran.should contain "after_run_in_a_block with 4"
      end
    end
  end

  describe "Avram::SaveOperation" do
    it "runs before_save, after_save, and after_commit callbacks" do
      SaveOperationWithCallbacks.create do |operation, post|
        operation.callbacks_that_ran.should contain "before_save_update_title"
        operation.callbacks_that_ran.should contain "before_save_in_a_block"
        post.should_not eq nil
        post.not_nil!.title.should eq "Saved Post"
        operation.callbacks_that_ran.should contain "after_save_notify_save_complete with Saved Post"
        operation.callbacks_that_ran.should contain "after_save_in_a_block with Saved Post"
        operation.callbacks_that_ran.should contain "after_commit_notify_commit_complete with Saved Post"
        operation.callbacks_that_ran.should contain "after_commit_in_a_block with Saved Post"
      end
    end
  end
end
