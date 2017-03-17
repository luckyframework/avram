abstract class BaseBox
  forward_missing_to @record

  def initialize
    @record = build_model
  end

  macro inherited
    @record : {{@type.name.gsub(/Box/, "").id}}
  end

  def self.build
    new.build
  end

  def build
    @record
  end

  def build_pair
    [@record, @record]
  end
end
