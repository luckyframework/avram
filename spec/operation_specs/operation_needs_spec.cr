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

private class SavePostWithNeeds < Post::SaveOperation
  needs info : String
  needs complex_data : JSON::Any
  attribute comment_count : Int32 = 2

  before_save do
    title.value = complex_data["title"].as_s
  end
end

describe "Avram::Operation needs" do
  it "sets up named args for needs" do
    OperationWithNeeds.run(tags: ["one", "two"], id: 3) do |operation, value|
      value.should eq "one, two"
      operation.tags.should eq ["one", "two"]
      operation.id.should eq 3
    end

    data = JSON::Any.new({"title" => JSON::Any.new("A complex title")})
    SavePostWithNeeds.create(info: "A curious post", complex_data: data) do |operation, record|
      record.try(&.title).should eq "A complex title"
      operation.info.should eq "A curious post"
      operation.complex_data.should be_a JSON::Any
    end
  end

  it "allows params to be passed in along with named args for needs" do
    params = Avram::Params.new({"title" => "test", "published" => "true"})
    OperationWithNeeds.run(params, tags: ["one", "two"], id: 3) do |operation, value|
      value.should eq "one, two"
      operation.tags.should eq ["one", "two"]
      operation.id.should eq 3
      operation.title.value.should eq "test"
      operation.published.value.should eq true
    end

    params = Avram::Params.new({"comment_count" => "5"})
    data = JSON::Any.new({"title" => JSON::Any.new("A complex title")})
    SavePostWithNeeds.create(params, info: "A curious post", complex_data: data) do |operation, record|
      record.try(&.title).should eq "A complex title"
      operation.info.should eq "A curious post"
      operation.complex_data.should be_a JSON::Any
      operation.comment_count.value.should eq 5
    end
  end
end
