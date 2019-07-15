class BucketBox < BaseBox
  def initialize
    bools [true, false]
    prices [39.99, 199.95]
    small_numbers [1_i16, 2_i16]
    numbers [100, 200]
    big_numbers [1000_i64, 2000_i64]
    names ["Mario", "Luigi"]
    dates [Time.utc, Time.utc]
    ids [UUID.random, UUID.random]
  end
end
