require "./spec_helper"

private class BucketQuery < Bucket::BaseQuery
end

describe "Array Columns" do
  it "fails when passing a single value to an array query" do
    BucketBox.new.numbers([1, 2, 3]).create
    expect_raises(PQ::PQError) do
      BucketQuery.new.numbers(1).select_count
    end
  end

  it "returns no results when passing in a proper query that doesn't match" do
    BucketBox.new.numbers([1, 2, 3]).create
    BucketQuery.new.numbers([1]).select_count.should eq 0
  end

  it "handles Array(Float64)" do
    BucketBox.create &.floaty_numbers([1.1, 2.2, 3.3, 4.4])
    bucket = BucketQuery.new.last
    bucket.floaty_numbers.should eq([1.1, 2.2, 3.3, 4.4])
  end
end
