require "../spec_helper"

private class OperationWithAttributes < Avram::Operation
  param_key :data
  attribute title : String
  attribute count : Int32
  attribute checked : Bool = false
  attribute thing : String = "taco"
  file_attribute :thumb

  def update_count
    count.value = 4
  end

  def run
    [title, count]
  end
end

private class SavePostWithAttributes < Post::SaveOperation
  param_key :post_data
  attribute comment_count : Int32
  attribute reviewed : Bool = false
  attribute author : String = "J.K. Simmons"
  file_attribute :thumb

  before_save do
    title.value = "Example Title"
  end

  def update_count
    comment_count.value = 4
  end
end

describe "Avram::Operation attributes" do
  it "is a PermittedAttribute" do
    OperationWithAttributes.run do |operation, _value|
      operation.title.should be_a(Avram::PermittedAttribute(String?))
      operation.title.name.should eq(:title)
      operation.title.param_key.should eq("data")
    end

    SavePostWithAttributes.create do |operation, _value|
      operation.comment_count.should be_a(Avram::PermittedAttribute(Int32?))
      operation.comment_count.name.should eq(:comment_count)
      operation.comment_count.param_key.should eq("post_data")
    end
  end

  it "generates a list of attributes" do
    OperationWithAttributes.run do |operation, _value|
      operation.attributes.map(&.name).should eq [:thumb, :thing, :checked, :count, :title]
    end
  end

  it "generates a list of attributes with inherited columns for SaveOperations" do
    SavePostWithAttributes.create do |operation, _value|
      operation.attributes.map(&.name).should eq [:thumb, :author, :reviewed, :comment_count, :custom_id, :created_at, :updated_at, :title, :published_at]
    end
  end

  it "has a value of nil when no default is given" do
    OperationWithAttributes.run do |operation, _value|
      operation.title.value.should eq nil
      operation.count.value.should eq nil
    end

    SavePostWithAttributes.create do |operation, _value|
      operation.comment_count.value.should eq nil
    end
  end

  it "assigns a default value to an attribute" do
    OperationWithAttributes.run do |operation, _value|
      operation.checked.value.should eq false
      operation.thing.value.should eq "taco"
    end

    SavePostWithAttributes.create do |operation, _value|
      operation.reviewed.value.should eq false
      operation.author.value.should eq "J.K. Simmons"
    end
  end

  it "overrides the default value with a param value" do
    params = Avram::Params.new({"checked" => "true", "title" => "Random Food", "count" => "4"})
    OperationWithAttributes.run(params) do |operation, _value|
      operation.title.value.should eq "Random Food"
      operation.count.value.should eq 4
      operation.checked.value.should eq true
    end

    params = Avram::Params.new({"comment_count" => "2", "reviewed" => "true", "author" => "Yellow Peanut"})
    SavePostWithAttributes.create(params) do |operation, _value|
      operation.comment_count.value.should eq 2
      operation.reviewed.value.should eq true
      operation.author.value.should eq "Yellow Peanut"
    end
  end

  it "sets the attribute value to nil if the param is an empty string" do
    params = Avram::Params.new({"title" => "", "thing" => ""})
    OperationWithAttributes.run(params) do |operation, _value|
      operation.title.value.should eq nil
      operation.thing.value.should eq nil
    end

    params = Avram::Params.new({"comment_count" => "", "reviewed" => ""})
    SavePostWithAttributes.create(params) do |operation, _value|
      operation.comment_count.value.should eq nil
      operation.reviewed.value.should eq false
    end
  end

  it "sets the param and value based on the passed in params" do
    params = Avram::Params.new({"title" => "secret"})
    OperationWithAttributes.run(params) do |operation, _value|
      operation.title.value.should eq "secret"
      operation.title.param.should eq "secret"
    end

    params = Avram::Params.new({"author" => "MegaMan"})
    SavePostWithAttributes.create(params) do |operation, _value|
      operation.author.value.should eq "MegaMan"
      operation.author.param.should eq "MegaMan"
    end
  end

  it "allows you to update an attribute value" do
    params = Avram::Params.new({"count" => "16"})
    OperationWithAttributes.run(params) do |operation, _value|
      operation.count.value.should eq 16
      operation.update_count
      operation.count.value.should eq 4
      operation.count.original_value.should eq 16
    end

    params = Avram::Params.new({"comment_count" => "2"})
    SavePostWithAttributes.create(params) do |operation, _value|
      operation.comment_count.value.should eq 2
      operation.update_count
      operation.comment_count.value.should eq 4
      operation.comment_count.original_value.should eq 2
    end
  end

  it "parses the value using the declared type" do
    params = Avram::Params.new({"checked" => "1"})
    OperationWithAttributes.run(params) do |operation, _value|
      operation.checked.value.should eq true
    end

    params = Avram::Params.new({"checked" => "0"})
    OperationWithAttributes.run(params) do |operation, _value|
      operation.checked.value.should eq false
    end

    params = Avram::Params.new({"reviewed" => "1"})
    SavePostWithAttributes.create(params) do |operation, _value|
      operation.reviewed.value.should eq true
    end

    params = Avram::Params.new({"reviewed" => "0"})
    SavePostWithAttributes.create(params) do |operation, _value|
      operation.reviewed.value.should eq false
    end
  end

  it "handles invalid params" do
    params = Avram::Params.new({"count" => "one"})
    OperationWithAttributes.run(params) do |operation, _value|
      operation.count.value.should eq nil
      operation.count.errors.first.should eq "is invalid"
    end

    params = Avram::Params.new({"comment_count" => "nope"})
    SavePostWithAttributes.create(params) do |operation, _value|
      operation.comment_count.value.should eq nil
      operation.comment_count.errors.first.should eq "is invalid"
    end
  end

  it "sets named args for attributes, leaves other empty" do
    OperationWithAttributes.run(title: "My Title", thing: "brown bear") do |operation, _value|
      operation.thing.value.should eq "brown bear"
      operation.title.value.should eq "My Title"
      operation.count.value.should eq nil
      operation.checked.value.should eq false
    end

    SavePostWithAttributes.create(author: "Pseud Onym", reviewed: true) do |operation, _value|
      operation.comment_count.value.should eq nil
      operation.author.value.should eq "Pseud Onym"
      operation.reviewed.value.should eq true
    end
  end

  describe "file_attribute" do
    it "is a PermittedAttribute" do
      OperationWithAttributes.run do |operation, _value|
        operation.thumb.should be_a(Avram::PermittedAttribute(Avram::Uploadable?))
        operation.thumb.name.should eq(:thumb)
        operation.thumb.param_key.should eq("data")
      end
    end

    it "is included in the list of attributes" do
      OperationWithAttributes.run do |operation, _value|
        operation.attributes.map(&.name).should contain(:thumb)
      end
    end

    it "gracefully handles invalid params" do
      params = Avram::Params.new({"thumb" => "not a file"})
      OperationWithAttributes.run(params) do |operation, _value|
        operation.thumb.value.should be_nil
        operation.thumb.errors.first.should eq "is invalid"
      end
    end

    it "includes file attribute errors when calling SaveOperation#valid?" do
      params = Avram::Params.new({"thumb" => "not a file"})
      SavePostWithAttributes.create(params) do |operation, _value|
        operation.valid?.should be_false
      end
    end

    it "can still save to the database" do
      params = Avram::UploadParams.new({"thumb" => Avram::UploadedFile.new("thumb.png")})
      SavePostWithAttributes.create(params) do |_operation, post|
        post.should_not eq nil
      end
    end
  end
end
