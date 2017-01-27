class User < LuckyRecord::Schema
  table :users do
    field :name
    field :age, Int32
    field :nickname, String, nilable: true
    field :joined_at, Time
  end
end

class UserRows < User::BaseRows
end
