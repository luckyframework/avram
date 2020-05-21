require "../spec_helper"

private class TestOperation < Avram::Operation
  def run
    "Lucky Test"
  end
end

private class TestOperationWithParamKey < Avram::Operation
  param_key :custom_key

  def run
    "Custom Key Test"
  end
end


describe Avram::Operation do
  describe "run" do
    it "returns the last statement from the run method" do
      TestOperation.run do |operation, value|
        value.should eq "Lucky Test"
      end
    end

    it "has access to the raw params passed in" do
      params = Avram::Params.new({"page" => "1", "per" => "50"})
      TestOperationWithParamKey.run(params) do |operation, value|
        operation.params.should eq params
        operation.params.get("page").should eq "1"
        value.should eq "Custom Key Test"
      end
    end
  end

  describe "param_key" do
    it "has a param_key based on the name of the operation" do
      TestOperation.param_key.should eq "test_operation"
    end

    it "sets a custom param key with the param_key macro" do
      TestOperationWithParamKey.param_key.should eq "custom_key"
    end
  end

  describe "valid?" do
    it "returns true when there's no attributes defined" do
      TestOperation.run do |operation, value|
        operation.valid?.should eq true
      end
    end
  end
end
