require "./spec_helper"

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
