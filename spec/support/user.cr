class User < LuckyRecord::Model
  table :users do
    field name : String
    field age : Int32
    field nickname : String?
    field joined_at : Time
  end
end

class UserRows < User::BaseRows
end
