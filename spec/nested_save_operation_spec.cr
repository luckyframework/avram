require "./spec_helper"

private class SaveBusiness < Business::SaveOperation
  permit_columns name
  has_one save_email_address : SaveEmailAddress
  has_one save_tax_id : SaveTaxId

  class SaveEmailAddress < EmailAddress::SaveOperation
    permit_columns address
  end

  class SaveTaxId < TaxId::SaveOperation
    permit_columns number
  end
end

private class NestedParams
  include Avram::Paramable

  @business : Hash(String, String) = {} of String => String
  @email_address : Hash(String, String) = {} of String => String
  @tax_id : Hash(String, String) = {} of String => String

  def initialize(@business, @email_address, @tax_id)
  end

  def nested?(key : String)
    if key == "email_address"
      @email_address
    elsif key == "tax_id"
      @tax_id
    elsif key == "business"
      @business
    else
      raise "What is this key!? #{key}"
    end
  end

  def nested(key : String)
    nested?(key)
  end

  def get?(key)
    raise "Not implemented"
  end

  def get(key)
    raise "Not implemented"
  end
end

describe "Avram::SaveOperation with nested operation" do
  context "when not all forms are valid" do
    it "does not save either" do
      params = NestedParams.new business: {"name" => "Fubar"},
        email_address: {"address" => ""},
        tax_id: {"number" => ""}

      SaveBusiness.create(params) do |operation, business|
        business.should be_nil
        operations_saved?(operation, false)
      end

      params = NestedParams.new business: {"name" => "Fubar"},
        email_address: {"address" => "123 Main St."},
        tax_id: {"number" => ""}

      SaveBusiness.create(params) do |operation, business|
        business.should be_nil
        operations_saved?(operation, false)
      end

      params = NestedParams.new business: {"name" => "Fubar"},
        email_address: {"address" => ""},
        tax_id: {"number" => "123"}

      SaveBusiness.create(params) do |operation, business|
        business.should be_nil
        operations_saved?(operation, false)
      end
    end
  end

  context "all forms are valid" do
    it "sets the relationship and saves both" do
      params = NestedParams.new business: {"name" => "Fubar"},
        email_address: {"address" => "foo@bar.com"},
        tax_id: {"number" => "123"}

      SaveBusiness.create(params) do |operation, business|
        operations_saved?(operation, saved?: true)
        operation.errors.keys.size.should eq 0
        operation.save_tax_id.errors.keys.size.should eq 0
        operation.save_email_address.errors.keys.size.should eq 0
        business.not_nil!.name.should eq "Fubar"
        business.not_nil!.email_address!.address.should eq "foo@bar.com"
        business.not_nil!.tax_id!.number.should eq 123
      end
    end
  end
end

private def operations_saved?(operation, saved? : Bool)
  operation.saved?.should eq(saved?)
  operation.save_email_address.saved?.should eq(saved?)
  operation.save_tax_id.saved?.should eq(saved?)
end
