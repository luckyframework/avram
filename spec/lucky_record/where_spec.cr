require "../spec_helper"

describe "LuckyRecord::Where" do
  describe "operators" do
    it "Equal" do
      where = LuckyRecord::Where::Equal.new(:name, "'Paul'")
      where.to_sql.should eq "name = 'Paul'"
    end

    it "GreatThan" do
      where = LuckyRecord::Where::GreaterThan.new(:age, "20")
      where.to_sql.should eq "age > 20"
    end

    it "GreatThanOrEqualTo" do
      where = LuckyRecord::Where::GreaterThanOrEqualTo.new(:age, "20")
      where.to_sql.should eq "age >= 20"
    end

    it "LessThan" do
      where = LuckyRecord::Where::LessThan.new(:age, "20")
      where.to_sql.should eq "age < 20"
    end

    it "LessThanOrEqualTo" do
      where = LuckyRecord::Where::LessThanOrEqualTo.new(:age, "20")
      where.to_sql.should eq "age <= 20"
    end
  end
end
