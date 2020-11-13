require "../spec_helper"

class SaveUserButNotReally < User::SaveOperation
  needs failure : Bool = false

  before_save do
    if failure
      self.valid = false
      add_error(:failure, "This failed quick")
      add_error(:failure, "Like, really quick")
    end
  end

end

class FailedOperation < Avram::Operation
  needs failure : Bool = false

  before_run do
    if failure
      self.valid = false
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
    FailedOperation.run(failure: true) do |op, _|
      op.errors[:oops].should eq ["this didn't work"]
      op.errors[:failure].should eq ["move right along"]
    end
  end

  it "sets a custom error for SaveOperation" do
    SaveUserButNotReally.create(failure: true) do |op, _|
      op.errors[:failure].should eq ["This failed quick", "Like, really quick"]
    end
  end
end