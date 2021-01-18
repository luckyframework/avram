class CustomerFactory < BaseFactory
  def initialize
    name sequence("test-customer")
  end
end
