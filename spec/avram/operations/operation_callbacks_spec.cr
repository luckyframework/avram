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

class OperationWithIf < Avram::Operation
  include TestableOperation
  attribute number : Int32 = 1

  before_run :update_number, if: :should_run_callback?

  def run
    number.value
  end

  private def update_number
    mark_callback("before_run_update_number")
    number.value = 10
  end

  private def should_run_callback?
    true
  end
end

class OperationWithUnless < Avram::Operation
  include TestableOperation
  attribute number : Int32 = 1

  before_run :update_number, unless: :skip_callback?

  def run
    number.value
  end

  private def update_number
    mark_callback("before_run_update_number")
    number.value = 20
  end

  private def skip_callback?
    true
  end
end

class OperationWithBlockUnless < Avram::Operation
  include TestableOperation
  attribute number : Int32 = 1

  before_run(unless: :skip_callback?) do
    mark_callback("before_run_block")
    number.value = 30
  end

  def run
    number.value
  end

  private def skip_callback?
    false
  end
end

describe "Avram::Operation callbacks" do
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

  it "runs before_run with if condition" do
    OperationWithIf.run do |operation, value|
      operation.callbacks_that_ran.should contain "before_run_update_number"
      value.should eq 10
    end
  end

  it "does not run before_run with unless condition" do
    OperationWithUnless.run do |operation, value|
      operation.callbacks_that_ran.should_not contain "before_run_update_number"
      value.should eq 1
    end
  end

  it "runs before_run block with unless condition" do
    OperationWithBlockUnless.run do |operation, value|
      operation.callbacks_that_ran.should contain "before_run_block"
      value.should eq 30
    end
  end
end
