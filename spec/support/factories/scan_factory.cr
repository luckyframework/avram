class ScanFactory < BaseFactory
  def initialize
    scanned_at Time.utc
  end
end
