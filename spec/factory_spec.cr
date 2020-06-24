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
    Avram::Factory.create(User).name.should eq "Test User"
    Avram::Factory.create(SignInCredential).user.name.should eq "Test User"
    weird_user = Avram::Factory.create(User, :weirdo)
    weird_user.name.should eq "User Test"
    creds = Avram::Factory.create(SignInCredential) do
      user { weird_user }
    end

    creds.user.name.should eq "User Test"
  end
end
