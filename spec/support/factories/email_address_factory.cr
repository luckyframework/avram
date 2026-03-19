class EmailAddressFactory < BaseFactory
  def initialize
    address "foo@bar.com"
    default true
  end
end
