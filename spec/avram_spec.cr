require "./spec_helper"
require "benchmark"

describe Avram do
  # Yeah, this is really a thing...
  it "does not bork Benchmark.memory" do
    total = Benchmark.memory { Array(Int32).new }
    total.should eq(32)
  end
end
