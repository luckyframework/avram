require "../spec_helper"

describe Avram::Attachment::Model do
  it "has an attachment" do
    item = AttachableItemFactory.create

    item.image.should be_nil
  end
end

describe Avram::Attachment::SaveOperation do
end

describe Avram::Attachment::DeleteOperation do
end
