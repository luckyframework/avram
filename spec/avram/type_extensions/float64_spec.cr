require "../../spec_helper"

describe "Float64" do
  it "parses Float64 from Float64" do
    result = Float64.adapter.parse(10.0)
    result.value.should eq(10.0)
  end

  it "parses Array(Float64) from Arrray(Float64)" do
    result = Float64.adapter.parse([10.0, 20.0])
    result.value.should eq([10.0, 20.0])
  end

  it "parses Float64 from PG::Numeric" do
    result = Float64.adapter.parse(n(0, 0, 0, 1, [] of Int16))
    result.value.should eq(0.0)
  end

  it "parses Array(Float64) from Array(PG::Numeric)" do
    result = Float64.adapter.parse(
      [
        n(0, 0, 0, 1, [] of Int16),
        n(1, 0, 0, 0, [1]),
      ]
    )
    result.value.should eq([0.0, 1.0])
  end

  it "parses Float64 from String" do
    result = Float64.adapter.parse("10.0")
    result.value.should eq(10.0)
  end

  it "parses Float64 from Int32" do
    result = Float64.adapter.parse(10.to_i32)
    result.value.should eq(10.0)
  end

  it "parses Float64 from Int64" do
    result = Float64.adapter.parse(10.to_i64)
    result.value.should eq(10.0)
  end
end

# See: https://github.com/will/crystal-pg/blob/cafec021f96f84e4b9d607f19920d9d62fdc6b90/spec/pg/numeric_spec.cr#L4-L6
private def n(nd, w, s, ds, d)
  PG::Numeric.new(nd.to_i16, w.to_i16, s.to_i16, ds.to_i16, d.map(&.to_i16))
end
