require "../../spec_helper"

private class SaveEmailAddress < EmailAddress::SaveOperation
end

include Avram::Expectations

describe Avram::Expectations::HaveErrorExpectation do
  describe "#have_error" do
    context "in positive assertions" do
      it "passes if attribute is invalid" do
        operation = SaveEmailAddress.new
        operation.address.add_error("is required")

        operation.should have_error
        operation.should have_error("is required")
        operation.should have_error(/\srequired/)

        operation.address.should have_error
        operation.address.should have_error("is required")
        operation.address.should have_error(/\srequired/)
      end

      it "fails if attribute is valid" do
        operation = SaveEmailAddress.new

        expect_raises Spec::AssertionFailed, "have an error" do
          operation.should have_error
        end

        expect_raises Spec::AssertionFailed, "have the error" do
          operation.should have_error("is required")
        end

        expect_raises Spec::AssertionFailed, "have the error" do
          operation.should have_error(/\srequired/)
        end

        expect_raises Spec::AssertionFailed, "have an error" do
          operation.address.should have_error
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.address.should have_error("is required")
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.address.should have_error(/\srequired/)
        end
      end

      it "fails if attribute is invalid but without the given message" do
        operation = SaveEmailAddress.new
        operation.address.add_error("is required")

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error("wrong message")
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error(/\smessage/)
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.address.should have_error("wrong message")
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.address.should have_error(/\smessage/)
        end
      end
    end

    context "in negative assertions" do
      it "passes if attribute is valid" do
        operation = SaveEmailAddress.new

        operation.should_not have_error
        operation.should_not have_error("is required")
        operation.should_not have_error(/\srequired/)

        operation.address.should_not have_error
        operation.address.should_not have_error("is required")
        operation.address.should_not have_error(/\srequired/)
      end

      it "fails if attribute is invalid" do
        operation = SaveEmailAddress.new
        operation.address.add_error("is required")

        expect_raises Spec::AssertionFailed, "not have an error" do
          operation.should_not have_error
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.should_not have_error("is required")
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.should_not have_error(/\srequired/)
        end

        expect_raises Spec::AssertionFailed, "not have an error" do
          operation.address.should_not have_error
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.address.should_not have_error("is required")
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.address.should_not have_error(/\srequired/)
        end
      end

      it "passes if attribute is invalid but without the given message" do
        operation = SaveEmailAddress.new
        operation.address.add_error("is required")

        operation.should_not have_error("wrong message")
        operation.should_not have_error(/\smessage/)

        operation.address.should_not have_error("wrong message")
        operation.address.should_not have_error(/\smessage/)
      end
    end
  end
end
