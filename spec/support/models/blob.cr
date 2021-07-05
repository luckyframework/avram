class BlobMetadata
  include JSON::Serializable

  property name : String?
  property code : Int32?
end

class MediaMetadata
  include JSON::Serializable

  property image : String?
end

class Blob < BaseModel
  table do
    column doc : JSON::Any?
    column metadata : BlobMetadata, serialize: true
    column media : MediaMetadata?, serialize: true
  end
end
