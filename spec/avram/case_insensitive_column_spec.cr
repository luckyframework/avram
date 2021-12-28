require "../spec_helper"

class EmailAddressQuery < EmailAddress::BaseQuery
end

private class SaveEmailAddress < EmailAddress::SaveOperation
  before_save do
    validate_uniqueness_of address
  end
end

describe "Case insensitive columns" do
  it "fails uniqueness validation" do
    existing = EmailAddressFactory.create

    SaveEmailAddress.create(address: existing.address) do |operation, _result|
      operation.valid?.should be_false
      operation.address.errors.should eq(["is already taken"])
    end
  end
end
