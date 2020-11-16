require "./spec_helper"

private class TestOperationWithDefaultParamKey < Avram::Operation
  attribute title : String

  def run
  end
end

private class TestOperationWithCustomParamKey < Avram::Operation
  param_key :test_op
  attribute title : String

  def run
  end
end

private class SaveUser < User::SaveOperation
end

private class NestedParams < Avram::FakeParams
  @data : Hash(String, String) = {} of String => String

  def initialize(@data)
  end

  def nested?(key : String) : Hash(String, String)
    if @data.keys.map(&.split(':').first).includes?(key)
      @data
    else
      {} of String => String
    end
  end
end

describe Avram::Paramable do
  describe "#has_key_for?" do
    it "returns true for the Operation with the proper key" do
      params = NestedParams.new({"test_operation_with_default_param_key:title" => "Test"})

      params.has_key_for?(TestOperationWithDefaultParamKey).should be_true
    end

    it "returns true for the Operation with a custom key" do
      params = NestedParams.new({"test_op:title" => "Test"})

      params.has_key_for?(TestOperationWithCustomParamKey).should be_true
    end

    it "returns false for the Operation with the improper key" do
      params = NestedParams.new({"bad_key:title" => "Test"})

      params.has_key_for?(TestOperationWithDefaultParamKey).should be_false
    end

    it "returns false for the Operation with no key" do
      params = NestedParams.new({"title" => "Test"})

      params.has_key_for?(TestOperationWithDefaultParamKey).should be_false
    end

    it "returns true for the SaveOperation with the proper key" do
      params = NestedParams.new({"user:name" => "Test"})

      params.has_key_for?(SaveUser).should be_true
    end

    it "returns false for the SaveOperation with the improper key" do
      params = NestedParams.new({"author:name" => "Test"})

      params.has_key_for?(SaveUser).should be_false
    end
  end
end
