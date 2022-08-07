require "../spec_helper"

describe Avram::Factory do
  it "can create a model without additional columns" do
    PlainModelFactory.create.id.should_not be_nil
  end

  describe "build_attributes" do
    it "generate a named_tuple with attributes" do
      BaseFactory::SEQUENCES["name"] = 0
      attributes = TagFactory.build_attributes
      attributes.should eq({custom_id: nil, created_at: nil, updated_at: nil, name: "name-1"})
    end

    it "overwrite attributes using a block" do
      attributes = TagFactory.build_attributes(&.name("new name"))
      attributes.should eq({custom_id: nil, created_at: nil, updated_at: nil, name: "new name"})
    end
  end

  describe "Sequences" do
    it "increases a value every time it's called" do
      BaseFactory::SEQUENCES["name"] = 0

      tag1 = TagFactory.create
      tag2 = TagFactory.create

      tag1.name.should eq("name-1")
      tag2.name.should eq("name-2")
    end

    it "can be overridden" do
      tag = TagFactory.create(&.name("not-a-sequence"))

      tag.name.should eq("not-a-sequence")
    end
  end

  describe "create_pair" do
    it "creates 2 tags" do
      tags = TagFactory.create_pair
      tags.size.should eq 2
      tags.class.name.should eq "Array(Tag)"
    end

    it "yields the block to both Factoryes" do
      users = UserFactory.create_pair do |factory|
        factory.age(30)
      end
      users.first.age.should eq 30
      users.last.age.should eq 30
    end

    it "works with sequences" do
      tags = TagFactory.create_pair do |factory|
        factory.name(factory.sequence("new-tag"))
      end
      tags.first.name.should eq "new-tag-1"
      tags.last.name.should eq "new-tag-2"
    end
  end

  describe "before_save" do
    it "sets the association before saving" do
      factory = ScanFactory.new
      line_item_id = LineItemFactory.create.id
      factory.before_save do
        factory.line_item_id(line_item_id)
      end
      scan = factory.create
      scan.line_item_id.should eq line_item_id
    end

    it "returns self and can be chaind" do
      factory = ScanFactory.new
      line_item_id = LineItemFactory.create.id
      scan = factory.before_save { factory.line_item_id(line_item_id) }.create
      scan.line_item_id.should eq line_item_id
    end
  end

  describe "after_save" do
    it "runs the block after the record is created" do
      factory = LineItemFactory.new
      factory.after_save do |line_item|
        ScanFactory.create &.line_item_id(line_item.id)
      end
      line_item = factory.create

      line_item.scans_count.should eq 1
    end

    it "returns self and can be chained" do
      line_item = LineItemFactory.create
      line_item.scans_count.should eq 0

      line_item = LineItemFactory.create &.with_scan
      line_item.scans_count.should eq 1
    end
  end
end
