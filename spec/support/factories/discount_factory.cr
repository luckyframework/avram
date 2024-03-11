class DiscountFactory < BaseFactory
  def initialize
    description "Awesome discount"
    in_cents 99
  end
end
