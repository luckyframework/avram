require "./spec_helper"

describe Avram::Box do
  it "can create a model without additional columns" do
    PlainModelBox.create.id.should_not be_nil
  end

  describe "build_attributes" do
    it "generate a named_tuple with attributes" do
      attributes = TagBox.build_attributes
      attributes.should eq({custom_id: nil, created_at: nil, updated_at: nil, name: "name-8"})
    end

    it "overwrite attributes passing a named tuple" do
      attributes = TagBox.build_attributes(&.name("new name"))
      attributes.should eq({custom_id: nil, created_at: nil, updated_at: nil, name: "new name"})
    end
  end

  describe "Sequences" do
    it "increases a value every time it's called" do
      BaseBox::SEQUENCES["name"] = 0

      tag1 = TagBox.create
      tag2 = TagBox.create

      tag1.name.should eq("name-1")
      tag2.name.should eq("name-2")
    end

    it "can be overridden" do
      tag = TagBox.create(&.name("not-a-sequence"))

      tag.name.should eq("not-a-sequence")
    end
  end

  describe "create_pair" do
    it "creates 2 tags" do
      tags = TagBox.create_pair
      tags.size.should eq 2
      tags.class.name.should eq "Array(Tag)"
    end

    it "yields the block to both boxes" do
      users = UserBox.create_pair do |box|
        box.age(30)
      end
      users.first.age.should eq 30
      users.last.age.should eq 30
    end

    it "works with sequences" do
      tags = TagBox.create_pair do |box|
        box.name(box.sequence("new-tag"))
      end
      tags.first.name.should eq "new-tag-1"
      tags.last.name.should eq "new-tag-2"
    end
  end
end
