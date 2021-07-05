class BlobFactory < BaseFactory
  def initialize
    doc JSON::Any.new({"foo" => JSON::Any.new("bar")})
    metadata_raw({name: "Test", code: 4}.to_json)
  end
end
