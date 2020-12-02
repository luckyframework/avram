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

private class CallbacksSaveOperation < Post::SaveOperation
  include TestableOperation
  needs rollback : Bool = false
  needs skip_set_required : Bool = false

  before_save setup_required_attributes

  before_save :run_before_save
  before_save { run_before_save_again }

  after_save :run_after_save
  after_save run_after_save_again

  after_commit :run_after_commit
  after_commit :run_after_commit_again

  def run_before_save
    mark_callback "before_save"
  end

  def run_before_save_again
    mark_callback "before_save_again"
  end

  def run_after_save(post : Post)
    mark_callback "after_save"
  end

  def run_after_save_again(post : Post)
    database.rollback if @rollback
    mark_callback "after_save_again"
  end

  def run_after_commit(post : Post)
    mark_callback "after_commit"
  end

  def run_after_commit_again(post : Post)
    mark_callback "after_commit_again"
  end

  private def mark_callback(callback_name)
    callbacks_that_ran << callback_name
  end

  private def setup_required_attributes
    title.value = "Title" unless @skip_set_required
  end
end

private class SaveLineItemBase < LineItem::SaveOperation
  permit_columns :name
  getter locked : Bool = false

  before_save lock

  def lock
    @locked = true
  end
end

private class SaveLineItemSub < SaveLineItemBase
  permit_columns :name
  getter loaded : Bool = false

  before_save load

  def load
    @loaded = true
  end
end

private class SaveOperationWithCallbacks < Post::SaveOperation
  include TestableOperation

  before_save :set_title, if: :title_is_needed?
  before_save { mark_callback("before_save_in_a_block") }

  after_save :notify_save_complete, unless: :already_notified?
  after_save do |saved_post|
    mark_callback("after_save_in_a_block with #{saved_post.title}")
  end

  after_commit :notify_commit_complete, if: :finalize_commit?
  after_commit do |saved_post|
    mark_callback("after_commit_in_a_block with #{saved_post.title}")
  end

  private def title_is_needed?
    true
  end

  private def already_notified?
    false
  end

  private def finalize_commit?
    true
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

private class UpdateOperationWithSkipCallbacks < SaveOperationWithCallbacks
  permit_columns :title

  before_save(unless: :skip_callback?) { mark_callback("before_save_in_a_block2") }
  after_save(unless: :skip_callback?) do |saved_post|
    mark_callback("after_save_in_a_block with #{saved_post.title}2")
  end
  after_commit(unless: :skip_callback?) do |saved_post|
    mark_callback("after_commit_in_a_block with #{saved_post.title}2")
  end

  # skip all the blocks
  private def skip_callback?
    true
  end

  # skip before_save :set_title
  private def title_is_needed?
    false
  end

  # skip after_save :notify_save_complete
  private def already_notified?
    true
  end

  # skip after_commit :notify_commit_complete
  private def finalize_commit?
    false
  end
end

private class UpdateOperationWithNoUpdates < Post::SaveOperation
  include TestableOperation

  after_completed :mark_operation_completed
  after_completed do |_saved_post|
    mark_callback("after_completed_in_a_block")
  end

  private def mark_operation_completed(_saved_post)
    mark_callback("after_completed_called")
  end
end

describe "Avram::SaveOperation callbacks" do
  it "does not run any callbacks if just validating" do
    operation = CallbacksSaveOperation.new
    operation.valid?

    operation.callbacks_that_ran.should eq([] of String)
  end

  it "runs all callbacks when saving successfully" do
    post = PostBox.create
    operation = CallbacksSaveOperation.new(post)
    operation.callbacks_that_ran.should eq([] of String)

    operation.save

    operation.callbacks_that_ran.should eq([
      "before_save",
      "before_save_again",
      "after_save",
      "after_save_again",
      "after_commit",
      "after_commit_again",
    ])
  end

  it "does not run after_commit if rolled back" do
    post = PostBox.create
    operation = CallbacksSaveOperation.new(post, rollback: true)
    operation.callbacks_that_ran.should eq([] of String)

    operation.save

    operation.callbacks_that_ran.should eq([
      "before_save",
      "before_save_again",
      "after_save",
    ])
  end

  it "runs before_save when validations fail" do
    operation = CallbacksSaveOperation.new(skip_set_required: true)
    operation.callbacks_that_ran.should eq([] of String)

    operation.save

    operation.valid?.should eq false
    operation.callbacks_that_ran.should eq(["before_save", "before_save_again"])
  end

  it "runs before_save in parent class and before_save in child class" do
    params = Avram::Params.new({"name" => "A fancy hat"})
    SaveLineItemSub.create params do |operation, record|
      operation.locked.should be_true
      operation.loaded.should be_true
      operation.saved?.should be_true
      record.should be_a(LineItem)
    end
  end

  it "skips running specified callbacks" do
    post = PostBox.create &.title("Existing Post")
    params = Avram::Params.new({"title" => "A fancy post"})

    UpdateOperationWithSkipCallbacks.update(post, params) do |operation, updated_post|
      updated_post.should_not eq nil
      updated_post.not_nil!.title.should eq "A fancy post"

      operation.callbacks_that_ran.should eq([
        "before_save_in_a_block",
        "after_save_in_a_block with A fancy post",
        "after_commit_in_a_block with A fancy post",
      ])
    end
  end

  it "runs after_completed callbacks even when nothing is being updated" do
    post = PostBox.create
    UpdateOperationWithNoUpdates.update(post) do |operation, _updated_post|
      operation.callbacks_that_ran.should eq([
        "after_completed_called",
        "after_completed_in_a_block",
      ])
    end
  end
end
