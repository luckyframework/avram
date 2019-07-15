require "./spec_helper"

private class CallbacksSaveOperation < Post::SaveOperation
  needs rollback : Bool = false

  @callbacks_that_ran = [] of String
  getter callbacks_that_ran

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
    title.value = "Title"
  end
end

describe "Avram::SaveOperation callbacks" do
  it "does not run after_* callbacks if just validating" do
    operation = CallbacksSaveOperation.new
    operation.callbacks_that_ran.should eq([] of String)

    operation.valid?

    operation.callbacks_that_ran.should eq(["before_save", "before_save_again"])
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
    operation = CallbacksSaveOperation.new(post)
    operation.callbacks_that_ran.should eq([] of String)

    operation.save

    operation.callbacks_that_ran.should eq([
      "before_save",
      "before_save_again",
      "after_save",
    ])
  end
end
