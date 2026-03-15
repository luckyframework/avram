require "../spec_helper"

describe Avram::Attachment::Model do
  it "has an attachment" do
    item = AttachableItemFactory.create

    item.image.should be_nil
  end

  it "deletes the file from storage when the record is deleted" do
    image_file = TestUploadedFile.new("photo.png")
    item = AttachableItem::SaveOperation.create!(image_file: image_file).reload
    stored = item.image.as(TestImageUploader::StoredFile)

    TestImageUploader::StoredFile.reset_deleted_ids
    AttachableItem::DeleteOperation.delete!(item)

    TestImageUploader::StoredFile.deleted_ids.should contain(stored.id)
  end
end

describe Avram::Attachment::SaveOperation do
  it "caches and promotes the attachment on save" do
    image_file = TestUploadedFile.new("photo.png")
    item = AttachableItem::SaveOperation.create!(image_file: image_file).reload

    item.image.should_not be_nil
    if image = item.image
      image.storage_key.should eq("store")
      image.id.should contain("attachable_item")
      image.id.should contain("image")
      image.id.should contain("photo.png")
    end
  end

  it "deletes the old attachment when uploading a new one" do
    image_file = TestUploadedFile.new("old_photo.png")
    item = AttachableItem::SaveOperation.create!(image_file: image_file)

    image_file = TestUploadedFile.new("new_photo.png")
    AttachableItem::SaveOperation.update!(item, image_file: image_file)

    item.reload.image.as(TestImageUploader::StoredFile).id
      .should contain("new_photo.png")
  end

  it "deletes the attachment when delete_image is true" do
    image_file = TestUploadedFile.new("old.png")
    item = AttachableItem::SaveOperation.create!(image_file: image_file)

    AttachableItem::SaveOperation.update!(item, delete_image: true)

    item.reload.image.should be_nil
  end
end

private class TestUploadedFile
  include Avram::Uploadable

  getter tempfile : File
  getter metadata : HTTP::FormData::FileMetadata

  def initialize(filename : String, content : String = "test content")
    @tempfile = File.tempfile(filename)
    @tempfile.print(content)
    @tempfile.rewind
    @metadata = HTTP::FormData::FileMetadata.new(filename: filename)
  end

  def filename : String
    @metadata.filename || ""
  end

  def blank? : Bool
    filename.blank?
  end
end
