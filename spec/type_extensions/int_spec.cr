require "../spec_helper"

describe "Int16" do
  it "parses Int16 from String" do
    result = Int16::Lucky.parse("10")
    result.value.should eq(10_i16)
  end

  it "parses Int16 from Int32" do
    result = Int16::Lucky.parse(400)
    result.value.should eq(400_i16)
  end

  it "returns FailedCast when overflow from Int16 to Int32/64" do
    result = Int16::Lucky.parse(1234556)
    result.value.should eq(nil)
    result.should be_a(Avram::Type::FailedCast)
  end

  it "returns nil if String is blank" do
    result = Int16::Lucky.parse("")
    result.value.should be_nil
    result.should be_a(Avram::Type::SuccessfulCast(Nil))
  end
end

describe "Int32" do
  it "parses Int32 from String" do
    result = Int32::Lucky.parse("10")
    result.value.should eq(10)
  end

  it "parses Int32 from Int64" do
    result = Int32::Lucky.parse(400_i64)
    result.value.should eq(400)
  end

  it "returns FailedCast when overflow from Int64 to Int32" do
    result = Int32::Lucky.parse(2147483648)
    result.value.should eq(nil)
    result.should be_a(Avram::Type::FailedCast)
  end

  it "returns nil if String is blank" do
    result = Int32::Lucky.parse("")
    result.value.should be_nil
    result.should be_a(Avram::Type::SuccessfulCast(Nil))
  end
end

describe "Int64" do
  it "parses Int64 from String" do
    result = Int64::Lucky.parse("10")
    result.value.should eq(10_i64)
  end

  it "parses Int64 from Int32" do
    result = Int64::Lucky.parse(400)
    result.value.should eq(400_i64)
  end

  it "returns nil if String is blank" do
    result = Int64::Lucky.parse("")
    result.value.should be_nil
    result.should be_a(Avram::Type::SuccessfulCast(Nil))
  end
end
