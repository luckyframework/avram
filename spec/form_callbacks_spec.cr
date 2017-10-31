require "./spec_helper"

private class CallbacksForm < Post::BaseForm
  @callbacks_that_ran = [] of String
  getter callbacks_that_ran

  def prepare
    setup_required_fields
    mark_callback "prepare"
  end

  def after_prepare
    mark_callback "after_prepare"
  end

  def before_save
    mark_callback "before_save"
  end

  def after_save(post : Post)
    mark_callback "after_save"
  end

  private def mark_callback(callback_name)
    callbacks_that_ran << callback_name
  end

  private def setup_required_fields
    title.value = "Title"
  end
end

describe "LuckyRecord::Form callbacks" do
  it "does not run the save callbacks if just validating" do
    form = CallbacksForm.new
    form.callbacks_that_ran.should eq([] of String)

    form.valid?
    form.callbacks_that_ran.should eq(["prepare", "after_prepare"])
  end

  it "runs all callbacks when saving" do
    form = CallbacksForm.new
    form.callbacks_that_ran.should eq([] of String)

    form.save

    form.callbacks_that_ran.should eq([
      "prepare",
      "after_prepare",
      "before_save",
      "after_save"
    ])
  end
end
