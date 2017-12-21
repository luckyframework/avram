require "./sign_in_credential"

class User < LuckyRecord::Model
  COLUMNS = "users.id, users.created_at, users.updated_at, users.name, users.age, users.nickname, users.joined_at"

  table users do
    field name : String
    field age : Int32
    field nickname : String?
    field joined_at : Time
    has_one sign_in_credential : SignInCredential?
  end
end

class UserQuery < User::BaseQuery
end
