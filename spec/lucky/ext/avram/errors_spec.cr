require "../../../spec_helper"

describe "Errors" do
  describe Avram::InvalidOperationError do
    it "is renderable and includes error details" do
      operation = User::SaveOperation.new
      operation.valid?.should be_false

      error = Avram::InvalidOperationError.new(operation)
      error.message.to_s.should start_with("Could not perform User::SaveOperation.\n\n")

      error.should be_a(Lucky::RenderableError)
      error.invalid_attribute_name.should eq("name")
      error.renderable_status.should eq(400)
      error.renderable_message.should contain("Invalid params")
      error.renderable_details.should eq("name is required")
    end
  end
end
