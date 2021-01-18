class TagFactory < BaseFactory
  def initialize
    name sequence("name")
  end
end
