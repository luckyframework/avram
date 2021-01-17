class BlobFactory < BaseFactory
  def initialize
    doc JSON::Any.new({"foo" => JSON::Any.new("bar")})
  end
end
