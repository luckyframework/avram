class User < Avram::Model
  COLUMN_SQL = "users.id, users.created_at, users.updated_at, users.name, users.age, users.nickname, users.joined_at, users.average_score"

  table do
    column name : String
    column age : Int32
    column nickname : String?
    column joined_at : Time
    column average_score : Float64?
    has_one sign_in_credential : SignInCredential?
  end
end

class UserQuery < User::BaseQuery
end
