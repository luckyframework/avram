require "../spec_helper"

private class SaveBucket < Bucket::SaveOperation
  permit_columns numbers
end

describe "Array Columns" do
  it "fails when passing a single value to an array query" do
    BucketFactory.new.numbers([1, 2, 3]).create
    expect_raises(PQ::PQError) do
      BucketQuery.new.numbers(1).select_count
    end
  end

  it "returns no results when passing in a proper query that doesn't match" do
    BucketFactory.new.numbers([1, 2, 3]).create
    BucketQuery.new.numbers([1]).select_count.should eq 0
  end

  it "handles Array(Float64)" do
    BucketFactory.create &.floaty_numbers([1.1, 2.2, 3.3, 4.4])
    bucket = BucketQuery.new.last
    bucket.floaty_numbers.should eq([1.1, 2.2, 3.3, 4.4])
  end

  it "handles Array(UUID)" do
    BucketFactory.create &.oody_things([UUID.new("40435254-4e21-45a6-9a1b-a1b9e7f5b444")])
    bucket = BucketQuery.new.last
    bucket.oody_things.should eq([UUID.new("40435254-4e21-45a6-9a1b-a1b9e7f5b444")])
  end

  it "handles optional Array" do
    BucketFactory.create &.numbers(nil)
    bucket = BucketQuery.new.last
    bucket.numbers.should be_nil
    bucket = SaveBucket.update!(bucket, numbers: [1, 2, 3])
    bucket.numbers.should eq([1, 2, 3])
    bucket = SaveBucket.update!(bucket, numbers: nil)
    bucket.numbers.should be_nil
  end
end
