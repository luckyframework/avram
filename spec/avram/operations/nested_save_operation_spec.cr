require "../../spec_helper"

private class SaveBusiness < Business::SaveOperation
  class SaveEmailAddress < EmailAddress::SaveOperation
    permit_columns address
  end

  class SaveTaxId < TaxId::SaveOperation
    permit_columns number
  end

  permit_columns name, latitude, longitude
  has_one save_email_address : SaveEmailAddress
  has_one save_tax_id : SaveTaxId
end

private class FakeNestedParams
  include Avram::Paramable
  @business : Hash(String, String) = {} of String => String
  @email_address : Hash(String, String) = {} of String => String
  @tax_id : Hash(String, String) = {} of String => String

  def initialize(@business, @email_address, @tax_id)
  end

  def nested(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested?(key : String) : Hash(String, String)
    data = case key
           when "email_address"
             @email_address
           when "tax_id"
             @tax_id
           when "business"
             @business
           else
             {} of String => String
           end

    data
  end

  def nested_arrays(key : String) : Hash(String, Array(String))
    nested_arrays?(key)
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    {} of String => Array(String)
  end

  def nested_file(key : String) : Hash(String, String)
    nested(key)
  end

  def nested_file?(key : String) : Hash(String, String)
    nested?(key)
  end

  def many_nested(key : String) : Array(Hash(String, String))
    many_nested?(key)
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    [] of Hash(String, String)
  end

  def get(key : String)
    get?(key)
  end

  def get?(key : String)
    nil
  end

  def get_all(key : String)
    get_all?(key)
  end

  def get_all?(key : String)
    nil
  end
end

describe "Avram::SaveOperation with nested operation" do
  context "when not all forms are valid" do
    it "does not create either" do
      params = FakeNestedParams.new business: {"name" => "Fubar"},
        email_address: {"address" => ""},
        tax_id: {"number" => ""}

      SaveBusiness.create(params) do |operation, business|
        business.should be_nil
        operation.valid?.should be_false
        operations_saved?(operation, false)
      end

      params = FakeNestedParams.new business: {"name" => "Fubar"},
        email_address: {"address" => "123 Main St."},
        tax_id: {"number" => ""}

      SaveBusiness.create(params) do |operation, business|
        business.should be_nil
        operation.valid?.should be_false
        operations_saved?(operation, false)
      end

      params = FakeNestedParams.new business: {"name" => "Fubar"},
        email_address: {"address" => ""},
        tax_id: {"number" => "123"}

      SaveBusiness.create(params) do |operation, business|
        business.should be_nil
        operation.valid?.should be_false
        operations_saved?(operation, false)
      end
    end

    it "does not update either" do
      name = "Foo"
      address = "current@foo.com"
      tax_num = 111

      new_name = "Fubar"
      new_address = "new@foo.com"
      new_tax_num = 123

      business = BusinessFactory.create &.name(name)
      email = EmailAddressFactory.create &.business_id(business.id)
        .address(address)
      tax = TaxIdFactory.create &.business_id(business.id).number(tax_num)

      params = FakeNestedParams.new business: {"name" => new_name},
        email_address: {"address" => new_address},
        tax_id: {"number" => new_tax_num.to_s}

      operation = SaveBusiness.new(business, params)
      operation.save_email_address.address.add_error("failed on purpose")
      operation.save_tax_id.number.add_error("failed on purpose")
      operation.save

      operation.valid?.should be_false
      operations_saved?(operation, false)
      business.reload.name.should eq(name)
      email.reload.address.should eq(address)
      tax.reload.number.should eq(tax_num)

      operation = SaveBusiness.new(business, params)
      operation.save_email_address.address.add_error("failed on purpose")
      operation.save

      operation.valid?.should be_false
      operations_saved?(operation, false)
      business.reload.name.should eq(name)
      email.reload.address.should eq(address)
      tax.reload.number.should eq(tax_num)

      operation = SaveBusiness.new(business, params)
      operation.save_tax_id.number.add_error("failed on purpose")
      operation.save

      operation.valid?.should be_false
      operations_saved?(operation, false)
      business.reload.name.should eq(name)
      email.reload.address.should eq(address)
      tax.reload.number.should eq(tax_num)

      params = FakeNestedParams.new business: {"name" => name},
        email_address: {"address" => new_address},
        tax_id: {"number" => new_tax_num.to_s}

      operation = SaveBusiness.new(business, params)
      operation.save_tax_id.number.add_error("failed on purpose")
      operation.save

      operation.valid?.should be_false
      operations_saved?(operation, false)
      business.reload.name.should eq(name)
      email.reload.address.should eq(address)
      tax.reload.number.should eq(tax_num)
    end
  end

  context "when all forms are valid" do
    it "sets the relationship and creates both" do
      params = FakeNestedParams.new business: {"name" => "Fubar", "latitude" => "46.383488", "longitude" => "22.774896"},
        email_address: {"address" => "foo@bar.com"},
        tax_id: {"number" => "123"}

      operation = SaveBusiness.new(params)
      operation.save_tax_id
      operation.save_email_address
      operation.save

      operation.valid?.should be_true
      operations_saved?(operation, saved?: true)
      operation.save_tax_id.valid?.should be_true
      operation.save_email_address.valid?.should be_true

      business = operation.record.as(Business)
      business.name.should eq "Fubar"
      business.email_address!.address.should eq "foo@bar.com"
      business.tax_id!.number.should eq 123
    end

    it "sets the relationship and updates both" do
      name = "Foo"
      address = "current@foo.com"
      tax_num = 111

      new_name = "Fubar"
      new_address = "new@foo.com"
      new_tax_num = 123

      business = BusinessFactory.create &.name(name)
      EmailAddressFactory.create &.business_id(business.id).address(address)
      TaxIdFactory.create &.business_id(business.id).number(tax_num)

      params = FakeNestedParams.new business: {"name" => new_name},
        email_address: {"address" => new_address},
        tax_id: {"number" => new_tax_num.to_s}

      SaveBusiness.update(business, params) do |operation, updated_business|
        operation.valid?.should be_true
        operations_saved?(operation, saved?: true)
        operation.save_tax_id.valid?.should be_true
        operation.save_email_address.valid?.should be_true
        updated_business.name.should eq new_name
        updated_business.email_address!.address.should eq new_address
        updated_business.tax_id!.number.should eq new_tax_num
      end

      new_address = "foo@bar.net"
      new_tax_num = 456

      business = business.reload

      params = FakeNestedParams.new business: {"name" => business.name},
        email_address: {"address" => new_address},
        tax_id: {"number" => new_tax_num.to_s}

      SaveBusiness.update(business, params) do |operation, updated_business|
        operation.valid?.should be_true
        operations_saved?(operation, saved?: true)
        operation.save_tax_id.valid?.should be_true
        operation.save_email_address.valid?.should be_true
        updated_business.name.should eq business.name
        updated_business.email_address!.address.should eq new_address
        updated_business.tax_id!.number.should eq new_tax_num
      end
    end
  end
end

private def operations_saved?(operation, saved? : Bool)
  operation.saved?.should eq(saved?)
  operation.save_email_address.saved?.should eq(saved?)
  operation.save_tax_id.saved?.should eq(saved?)
end
