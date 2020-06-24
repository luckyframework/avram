require "./spec_helper"

Avram::Factory.register(User) do
  name { "Test User" }
  available_for_hire { true }
  age { 19 }
  joined_at { Time.utc }

  trait :weirdo do
    name { "User Test" }
  end
end

Avram::Factory.register(SignInCredential) do
  user
end

describe Avram::Factory do
  it "works" do
    Avram::Factory.create(User)
    Avram::Factory.create(SignInCredential)
    pp! Avram::Factory.create(User, :weirdo)
  end
end
