require "../spec_helper"

private class OperationWithAttributes < Avram::Operation
  param_key :data
  attribute title : String
  attribute count : Int32
  attribute checked : Bool = false
  attribute thing : String = "taco"

  def update_count
    count.value = 4
  end

  def run
    [title, count]
  end
end


describe "attribute in operations" do
  it "is a PermittedAttribute" do
    OperationWithAttributes.run do |operation, value|
      operation.title.should be_a(Avram::PermittedAttribute(String?))
      operation.title.name.should eq(:title)
      operation.title.param_key.should eq("data")
    end
  end

  it "generates a list of attributes" do
    OperationWithAttributes.run do |operation, value|
      operation.attributes.map(&.name).should eq [:thing, :checked, :count, :title]
    end
  end

  it "sets a default value of nil" do
    OperationWithAttributes.run do |operation, value|
      operation.title.value.should eq nil
      operation.count.value.should eq nil
    end
  end

  it "assigns the default value to an attribute if one is set and no param is given" do
    OperationWithAttributes.run do |operation, value|
      operation.checked.value.should eq false
      operation.thing.value.should eq "taco"
    end
  end

  it "overrides the default value with a param if one is given" do
    params = Avram::Params.new({"checked" => "true", "title" => "Random Food", "count" => "4"})
    OperationWithAttributes.run(params) do |operation, value|
      operation.title.value.should eq "Random Food"
      operation.count.value.should eq 4
      operation.checked.value.should eq true
    end
  end

  it "sets the attribute value to nil if the param is an empty string" do
    params = Avram::Params.new({"title" => "", "thing" => ""})
    OperationWithAttributes.run(params) do |operation, value|
      operation.title.value.should eq nil
      operation.thing.value.should eq nil
    end
  end

  it "sets the param and value based on the passed in params" do
    params = Avram::Params.new({"title" => "secret"})
    OperationWithAttributes.run(params) do |operation, value|
      operation.title.value.should eq "secret"
      operation.title.param.should eq "secret"
    end
  end

  it "allows you to update an attribute value" do
    params = Avram::Params.new({"count" => "16"})
    OperationWithAttributes.run(params) do |operation, value|
      operation.count.value.should eq 16
      operation.update_count
      operation.count.value.should eq 4
      operation.count.original_value.should eq 16
    end
  end

  it "parses the value using the declared type" do
    params = Avram::Params.new({"checked" => "1"})
    OperationWithAttributes.run(params) do |operation, value|
      operation.checked.value.should eq true
    end
    
    params = Avram::Params.new({"checked" => "0"})
    OperationWithAttributes.run(params) do |operation, value|
      operation.checked.value.should eq false
    end
  end

  it "gracefully handles invalid params" do
    params = Avram::Params.new({"count" => "one"})
    OperationWithAttributes.run(params) do |operation, value|
      operation.count.value.should eq nil
      operation.count.errors.first.should eq "is invalid"
    end
  end

  # it "sets named args for attributes, leaves other empty" do
  #   OperationWithAttributes.run(title: "My Title", thing: "brown bear") do |operation, value|
  #     operation.thing.value.should eq "brown bear"
  #     operation.title.value.should eq "My Title"
  #     operation.count.value.should eq nil
  #     operation.checked.value.should eq false
  #   end
  # end
end
