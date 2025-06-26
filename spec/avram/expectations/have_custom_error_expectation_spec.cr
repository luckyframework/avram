require "../../spec_helper"

private class SaveEmailAddress < EmailAddress::SaveOperation
end

include Avram::Expectations

describe Avram::Expectations::HaveCustomErrorExpectation do
  describe "#have_error" do
    context "in positive assertions" do
      it "passes if attribute is invalid" do
        operation = SaveEmailAddress.new
        operation.add_error(:providers, "is empty")

        operation.should have_error
        operation.should have_error("is empty")
        operation.should have_error(/\sempty/)

        operation.should have_error(:providers)
        operation.should have_error(:providers, "is empty")
        operation.should have_error(:providers, /\sempty/)
      end

      it "fails if attribute is valid" do
        operation = SaveEmailAddress.new

        expect_raises Spec::AssertionFailed, "have an error" do
          operation.should have_error(:providers)
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error(:providers, "is empty")
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error(:providers, /\sempty/)
        end
      end

      it "fails if attribute is invalid but without the given message" do
        operation = SaveEmailAddress.new
        operation.add_error(:providers, "is empty")

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error("wrong message")
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error(/\smessage/)
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error(:providers, "wrong message")
        end

        expect_raises Spec::AssertionFailed, "have the error " do
          operation.should have_error(:providers, /\smessage/)
        end
      end
    end

    context "in negative assertions" do
      it "passes if attribute is valid" do
        operation = SaveEmailAddress.new

        operation.should_not have_error(:providers)
        operation.should_not have_error(:providers, "is empty")
        operation.should_not have_error(:providers, /\sempty/)
      end

      it "fails if attribute is invalid" do
        operation = SaveEmailAddress.new
        operation.add_error(:providers, "is empty")

        expect_raises Spec::AssertionFailed, "not have an error" do
          operation.should_not have_error
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.should_not have_error("is empty")
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.should_not have_error(/\sempty/)
        end

        expect_raises Spec::AssertionFailed, "not have an error" do
          operation.should_not have_error(:providers)
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.should_not have_error(:providers, "is empty")
        end

        expect_raises Spec::AssertionFailed, "not have the error " do
          operation.should_not have_error(:providers, /\sempty/)
        end
      end

      it "passes if attribute is invalid but without the given message" do
        operation = SaveEmailAddress.new
        operation.add_error(:providers, "is required")

        operation.should_not have_error("wrong message")
        operation.should_not have_error(/\smessage/)

        operation.should_not have_error(:providers, "wrong message")
        operation.should_not have_error(:providers, /\smessage/)
      end
    end
  end
end
