class BlobMetadata
  include JSON::Serializable

  property name : String
  property code : Int32
end

class Blob < BaseModel
  table do
    column doc : JSON::Any?
    serialized metadata : BlobMetadata?
  end
end
