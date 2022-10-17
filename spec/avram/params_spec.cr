require "../spec_helper"

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

private class NestedParams < Avram::Params
  def nested?(key : String) : Hash(String, String)
    if @hash.keys.map(&.split(':').first).includes?(key)
      super
    else
      {} of String => String
    end
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    if @hash.keys.map(&.split(':').first).includes?(key)
      super
    else
      {} of String => Array(String)
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

private class SaveToken < Token::SaveOperation
  permit_columns :name, :scopes
end

describe Avram::Params do
  it "accepts hashes with all string values" do
    name = "Auth token"
    params = Avram::Params.new({"name" => name})

    SaveToken.create(params) do |_, token|
      token.should be_a(Token)

      token.try do |_token|
        _token.name.should eq(name)
      end
    end
  end

  it "accepts hashes with all array values" do
    scopes = ["profile", "openid"]
    params = Avram::Params.new({"scopes" => scopes})

    SaveToken.create(params) do |_, token|
      token.should be_a(Token)

      token.try do |_token|
        _token.scopes.should eq(scopes)
      end
    end
  end

  it "accepts hashes with a mixture of array and string values" do
    name = "Auth token"
    scopes = ["profile", "openid"]

    params = Avram::Params.new({
      "name"   => name,
      "scopes" => scopes,
    })

    SaveToken.create(params) do |_, token|
      token.should be_a(Token)

      token.try do |_token|
        _token.name.should eq(name)
        _token.scopes.should eq(scopes)
      end
    end
  end
end
