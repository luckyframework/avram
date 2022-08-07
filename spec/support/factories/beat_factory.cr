class BeatFactory < BaseFactory
  def initialize
    hash(Random.new.random_bytes(4))
  end
end
