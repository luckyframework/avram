require "./spec_helper"

private class CallbacksSaveOperation < Post::SaveOperation
  @callbacks_that_ran = [] of String
  getter callbacks_that_ran

  before_save :run_before_save
  before_save run_before_save_again

  before_create :run_before_create
  before_create run_before_create_again

  before_update :run_before_update
  before_update :run_before_update_again

  after_save :run_after_save
  after_save run_after_save_again

  after_create :run_after_create
  after_create run_after_create_again

  after_update :run_after_update
  after_update :run_after_update_again

  def prepare
    setup_required_fields
    mark_callback "prepare"
  end

  def after_prepare
    mark_callback "after_prepare"
  end

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
    mark_callback "after_save_again"
  end

  def run_before_create
    mark_callback "before_create"
  end

  def run_before_create_again
    mark_callback "before_create_again"
  end

  def run_after_create(post : Post)
    mark_callback "after_create"
  end

  def run_after_create_again(post : Post)
    mark_callback "after_create_again"
  end

  def run_before_update
    mark_callback "before_update"
  end

  def run_before_update_again
    mark_callback "before_update_again"
  end

  def run_after_update(post : Post)
    mark_callback "after_update"
  end

  def run_after_update_again(post : Post)
    mark_callback "after_update_again"
  end

  private def mark_callback(callback_name)
    callbacks_that_ran << callback_name
  end

  private def setup_required_fields
    title.value = "Title"
  end
end

describe "Avram::SaveOperation callbacks" do
  it "does not run the save callbacks if just validating" do
    form = CallbacksSaveOperation.new
    form.callbacks_that_ran.should eq([] of String)

    form.valid?
    form.callbacks_that_ran.should eq(["prepare", "after_prepare"])
  end

  it "runs all callbacks except *_update when creating" do
    form = CallbacksSaveOperation.new
    form.callbacks_that_ran.should eq([] of String)

    form.save

    form.callbacks_that_ran.should eq([
      "prepare",
      "after_prepare",
      "before_save",
      "before_save_again",
      "before_create",
      "before_create_again",
      "after_save",
      "after_save_again",
      "after_create",
      "after_create_again",
    ])
  end

  it "runs all callbacks except *_update when creating" do
    post = PostBox.create
    form = CallbacksSaveOperation.new(post)
    form.callbacks_that_ran.should eq([] of String)

    form.save

    form.callbacks_that_ran.should eq([
      "prepare",
      "after_prepare",
      "before_save",
      "before_save_again",
      "before_update",
      "before_update_again",
      "after_save",
      "after_save_again",
      "after_update",
      "after_update_again",
    ])
  end
end
