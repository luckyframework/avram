class UserFactory < BaseFactory
  def initialize
    name "Paul Smith"
    joined_at Time.utc
    age 18
  end

  def build_model
    User.new(
      id: 123_i64,
      created_at: Time.utc,
      updated_at: Time.utc,
      joined_at: Time.utc,
      age: 18,
      year_born: nil,
      name: "Paul Smith",
      nickname: nil,
      total_score: nil,
      average_score: nil,
      available_for_hire: nil
    )
  end
end
