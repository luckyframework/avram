require "json"

abstract struct Lucky::Attachment::Uploader
end

abstract class Lucky::Attachment::StoredFile
  alias MetadataValue = String | Int64 | Int32 | Float64 | Bool | Nil
  alias MetadataHash = Hash(String, MetadataValue)

  include JSON::Serializable

  @[JSON::Field(ignore: true)]
  @io : IO?

  def initialize(
    @id : String,
    @storage_key : String,
    @metadata : MetadataHash = MetadataHash.new,
  )
  end
end

struct TestImageUploader < Lucky::Attachment::Uploader
  def self.path_prefix : String
    ":model/:id/:attachment"
  end

  def self.cache(io : IO, path_prefix : String, filename : String?) : StoredFile
    StoredFile.new(
      id: File.join(path_prefix, filename || "test.png"),
      storage_key: "cache"
    )
  end

  def self.promote(file : StoredFile, location : String) : StoredFile
    StoredFile.new(
      id: location,
      storage_key: "store"
    )
  end

  class StoredFile < ::Lucky::Attachment::StoredFile
    def self.adapter
      Lucky(self)
    end

    @@deleted_ids = [] of String

    def self.deleted_ids : Array(String)
      @@deleted_ids
    end

    def self.reset_deleted_ids : Nil
      @@deleted_ids.clear
    end

    getter id = "file_id"
    getter storage_key = "store"

    def delete : Nil
      @@deleted_ids << @id
    end
  end
end

class AttachableItem < BaseModel
  include Avram::Attachment::Model

  skip_default_columns

  table do
    primary_key id : Int64
    attach image : TestImageUploader::StoredFile?
    timestamps
  end
end

class AttachableItem::SaveOperation
  attach image
end
