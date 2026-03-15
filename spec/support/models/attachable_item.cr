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

  class StoredFile < ::Lucky::Attachment::StoredFile
    def self.adapter
      Lucky(self)
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
