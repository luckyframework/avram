require "../spec_helper"

describe LuckyRecord::Schema do
  it "sets up initializers based on the fields" do
    User.new id: 123,
      name: "Name",
      age: 24,
      joined_at: Time.now,
      created_at: Time.now,
      updated_at: Time.now,
      nickname: nil
  end
end
