class LineItemFactory < BaseFactory
  def initialize
    name "A pair of shoes"
  end

  def with_scan
    after_save do |line_item|
      ScanFactory.create &.line_item_id(line_item.id)
    end
  end
end
