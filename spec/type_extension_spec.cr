require "./spec_helper.cr"

class CompanyQuery < Company::BaseQuery
end

class CompanyForm < Company::BaseForm
  allow :sales, :earnings

  def prepare
    validate_required sales
    validate_required earnings
  end
end

describe "TypeExtensions" do
  it "should work in boxes" do
    CompanyBox.save
    company = CompanyQuery.new.first
    company.sales.should eq Int64::MAX
    company.earnings.should eq 1.0

    company2 = CompanyBox.new.sales(10_i64).earnings(2.0).save
    company2.sales.should eq 10_i64
    company2.earnings.should eq 2.0
  end

  it "should convert params and save forms" do
    form = CompanyForm.new({"sales" => "10", "earnings" => "10"})
    form.sales.value.should eq 10_i64
    form.earnings.value.should eq 10.0
  end

  it "Int64 and Float64 should allow querying with Int32" do
    CompanyBox.new.sales(10_i64).earnings(1.0).save
    using_sales = CompanyQuery.new.sales(10).first
    using_sales.sales.should eq 10_i64

    using_earnings = CompanyQuery.new.earnings(1).first
    using_earnings.earnings.should eq 1.0
  end
end
