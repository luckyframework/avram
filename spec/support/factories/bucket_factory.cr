class BucketFactory < BaseFactory
  def initialize
    bools [true, false]
    small_numbers [1_i16, 2_i16]
    numbers [100, 200]
    big_numbers [1000_i64, 2000_i64]
    names ["Mario", "Luigi"]
    floaty_numbers [0.0]
    oody_things [UUID.random]
  end
end
