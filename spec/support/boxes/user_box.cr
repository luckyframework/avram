class UserBox < BaseBox
  def build_model
    User.new(
      id: 123,
      created_at: Time.now,
      updated_at: Time.now,
      joined_at: Time.now,
      age: 18,
      name: "Paul Smith",
      nickname: nil
    )
  end
end
