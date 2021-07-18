class BlobFactory < BaseFactory
  def initialize
    doc JSON::Any.new({"foo" => JSON::Any.new("bar")})
    metadata(BlobMetadata.from_json({name: "Test", code: 4}.to_json))
    media nil
  end
end
