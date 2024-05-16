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

  it "handles Array(Enum)" do
    BucketFactory.create &.enums([Bucket::Size::Large, Bucket::Size::Tub])
    bucket = BucketQuery.new.last
    bucket.enums.should eq([Bucket::Size::Large, Bucket::Size::Tub])
    bucket = SaveBucket.update!(bucket, enums: [Bucket::Size::Small])
    bucket.enums.should eq([Bucket::Size::Small])
  end

  describe "the #have_any? method" do
    it "returns the records with have at least one element of the provided ones" do
      BucketFactory.new.numbers([1, 2]).create
      BucketFactory.new.numbers([1, 3]).create

      bucket = BucketQuery.new.numbers.have_any?([1, 2, 3]).select_count
      bucket.should eq 2

      bucket = BucketQuery.new.numbers.have_any?([1, 3]).select_count
      bucket.should eq 2

      bucket = BucketQuery.new.numbers.have_any?([3, 4]).select_count
      bucket.should eq 1

      bucket = BucketQuery.new.numbers.have_any?([4]).select_count
      bucket.should eq 0
    end

    it "returns nothing with an empty array" do
      BucketFactory.new.numbers([1, 2]).create
      bucket = BucketQuery.new.numbers.have_any?([] of Int64).select_count
      bucket.should eq 0
    end

    it "negates with not" do
      BucketFactory.new.numbers([1, 2]).create
      bucket = BucketQuery.new.numbers.not.have_any?([3]).select_count
      bucket.should eq 1
    end
  end
end
