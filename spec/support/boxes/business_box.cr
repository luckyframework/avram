class BusinessBox < BaseBox
  def initialize
    name "My Biz"
  end
end

class EmailAddressBox < BaseBox
  def initialize
    address "foo@bar.com"
  end
end
