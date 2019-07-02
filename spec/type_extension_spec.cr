require "./spec_helper.cr"

class CompanyQuery < Company::BaseQuery
end

class SaveCompany < Company::SaveOperation
  permit_columns :sales, :earnings

  def prepare
    validate_required sales
    validate_required earnings
  end
end

describe "TypeExtensions" do
  it "should work in boxes" do
    CompanyBox.create
    company = CompanyQuery.new.first
    company.sales.should eq Int64::MAX
    company.earnings.should eq 1.0

    company2 = CompanyBox.create &.sales(10_i64).earnings(2.0)
    company2.sales.should eq 10_i64
    company2.earnings.should eq 2.0
  end

  it "should convert params and save forms" do
    form = SaveCompany.new({"sales" => "10", "earnings" => "10"})
    form.sales.value.should eq 10_i64
    form.earnings.value.should eq 10.0
  end

  it "Int64 and Float64 should allow querying with Int32" do
    CompanyBox.create &.sales(10).earnings(1.0)
    using_sales = CompanyQuery.new.sales(10).first
    using_sales.sales.should eq 10_i64

    using_earnings = CompanyQuery.new.earnings(1).first
    using_earnings.earnings.should eq 1.0
  end

  it "Int16 should allow querying with Int32" do
    MenuOptionBox.create &.title("test").option_value(4_i16)
    opt = MenuOptionQuery.new.option_value(4).first
    opt.option_value.should eq 4_i16
  end
end
