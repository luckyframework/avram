require "./spec_helper"

Avram::Factory.register(User) do
  name { "Test User" }
  available_for_hire { true }
  age { 19 }
  joined_at { Time.utc }
end

describe Avram::Factory do
  it "works" do
    user = Avram::Factory.create(User)
    pp! user
  end
end
