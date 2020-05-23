require "../spec_helper"

private class OperationWithNeeds < Avram::Operation
  needs tags : Array(String)
  needs id : Int32
  attribute title : String
  attribute published : Bool = false

  def run
    tags.join(", ")
  end
end

describe "Avram::Operation needs" do
  it "sets up named args on run" do
    OperationWithNeeds.run(tags: ["one", "two"], id: 3) do |operation, value|
      value.should eq "one, two"
      operation.tags.should eq ["one", "two"]
      operation.id.should eq 3
    end
  end

  it "sets up named args on run when params are passed in" do
    params = Avram::Params.new({"title" => "test", "published" => "true"})
    OperationWithNeeds.run(params, tags: ["one", "two"], id: 3) do |operation, value|
      value.should eq "one, two"
      operation.tags.should eq ["one", "two"]
      operation.id.should eq 3
      operation.title.value.should eq "test"
      operation.published.value.should eq true
    end
  end
end
