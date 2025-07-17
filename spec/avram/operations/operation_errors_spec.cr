require "../../spec_helper"

class SaveUserButNotReally < User::SaveOperation
  needs failure : Bool = false

  before_save do
    if failure
      add_error(:failure, "This failed quick")
      add_error(:failure, "Like, really quick")
    end
  end
end

class FailedOperation < Avram::Operation
  needs failure : Bool = false

  before_run do
    if failure
      add_error(:oops, "this didn't work")
      add_error(:failure, "move right along")
    end
  end

  def run
    "noop"
  end
end

describe Avram::OperationErrors do
  it "sets a custom error for Operation" do
    operation = FailedOperation.new(failure: true)
    operation.add_error(:fail, "Not valid")
    operation.valid?.should eq false
    operation.errors[:fail].should eq ["Not valid"]
  end

  it "returns a nil value when there's a custom error on Operation" do
    FailedOperation.run(failure: true) do |operation, value|
      value.should eq nil
      operation.valid?.should eq false
      operation.errors[:oops].should eq ["this didn't work"]
      operation.errors[:failure].should eq ["move right along"]
    end
  end

  it "sets a custom error for SaveOperation" do
    operation = SaveUserButNotReally.new(failure: true)
    operation.add_error(:fail, "User did not save")
    operation.valid?.should eq false
    operation.errors[:fail].should eq ["User did not save"]
  end

  it "returns a failed save status for SaveOperation" do
    SaveUserButNotReally.create(failure: true) do |operation, value|
      value.should eq nil
      operation.valid?.should eq false
      operation.errors[:failure].should eq ["This failed quick", "Like, really quick"]
      operation.save_status.should eq SaveUserButNotReally::OperationStatus::SaveFailed
    end
  end
end
