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

  describe "#nested" do
    it "decodes a JSON object string value for the given key" do
      params = Avram::Params.new({"reaction" => %({"emoji":"👍"})})

      params.nested("reaction").should eq({"emoji" => "👍"})
    end

    it "falls back to returning all flat string values when the key is missing" do
      params = Avram::Params.new({"body" => "Hello"})

      params.nested("reaction").should eq({"body" => "Hello"})
    end

    it "falls back to returning all flat string values when the value isn't JSON" do
      params = Avram::Params.new({"body" => "Hello", "reaction" => "not json"})

      params.nested("reaction").should eq({"body" => "Hello", "reaction" => "not json"})
    end

    it "extracts values from keys prefixed with 'key:', as submitted by a URL-encoded/multipart HTML form" do
      params = Avram::Params.new({"body" => "Hello", "reaction:emoji" => "👍"})

      params.nested("reaction").should eq({"emoji" => "👍"})
    end

    it "prefers a JSON object string value over form-encoded 'key:' keys" do
      params = Avram::Params.new({"reaction" => %({"emoji":"👍"}), "reaction:emoji" => "😂"})

      params.nested("reaction").should eq({"emoji" => "👍"})
    end
  end

  describe "#many_nested" do
    it "decodes a JSON array of objects string value for the given key" do
      params = Avram::Params.new({"customers" => [{"name" => "Customer One"}, {"name" => "Customer Two"}].to_json})

      params.many_nested("customers").should eq([{"name" => "Customer One"}, {"name" => "Customer Two"}])
    end

    it "decodes a JSON empty array string value into an empty Array" do
      params = Avram::Params.new({"customers" => "[]"})

      params.many_nested("customers").should eq([] of Hash(String, String))
    end

    it "falls back to wrapping all flat string values in a single item when the key is missing" do
      params = Avram::Params.new({"name" => "Customer One"})

      params.many_nested("customers").should eq([{"name" => "Customer One"}])
    end

    it "falls back to wrapping all flat string values in a single item when the array contains a non-object element" do
      params = Avram::Params.new({"name" => "Customer One", "customers" => %(["not an object"])})

      params.many_nested("customers").should eq([{"name" => "Customer One", "customers" => %(["not an object"])}])
    end

    it "groups keys matching 'key[index]:rest', as submitted by a URL-encoded/multipart HTML form" do
      params = Avram::Params.new({
        "name"              => "Employee One",
        "customers[0]:name" => "Customer One",
        "customers[0]:id"   => "1",
        "customers[1]:name" => "Customer Two",
      })

      params.many_nested("customers").should eq([
        {"name" => "Customer One", "id" => "1"},
        {"name" => "Customer Two"},
      ])
    end

    it "keeps further nested form-encoded keys intact within each grouped item" do
      params = Avram::Params.new({
        "customers[0]:name"          => "Customer One",
        "customers[0]:orders[0]:sku" => "ABC",
      })

      params.many_nested("customers").should eq([
        {"name" => "Customer One", "orders[0]:sku" => "ABC"},
      ])
    end

    it "prefers a JSON array string value over form-encoded 'key[index]:' keys" do
      params = Avram::Params.new({
        "customers"         => [{"name" => "Customer One"}].to_json,
        "customers[0]:name" => "Customer Two",
      })

      params.many_nested("customers").should eq([{"name" => "Customer One"}])
    end
  end
end
