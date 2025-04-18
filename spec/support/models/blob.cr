class BlobMetadata
  include JSON::Serializable

  property name : String?
  property code : Int32?
end

class MediaMetadata
  include JSON::Serializable

  property image : String?
end

class ServerMetadata
  include JSON::Serializable
  property host : String
end

class Blob < BaseModel
  COLUMN_SQL = %("blobs"."id", "blobs"."created_at", "blobs"."updated_at", "blobs"."doc", "blobs"."metadata", "blobs"."media", "blobs"."servers")
  table do
    column doc : JSON::Any?
    column metadata : BlobMetadata, serialize: true
    column media : MediaMetadata? = nil, serialize: true
    column servers : Array(ServerMetadata) = Array(ServerMetadata).from_json("[]"), serialize: true
  end
end
