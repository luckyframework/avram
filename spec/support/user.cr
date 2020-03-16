class User < BaseModel
  COLUMN_SQL = "users.id, users.created_at, users.updated_at, users.name, users.age, users.year_born, users.nickname, users.joined_at, users.total_score, users.average_score, users.available_for_hire"

  table do
    column name : String
    column age : Int32
    column year_born : Int16?
    column nickname : String?
    column joined_at : Time
    column total_score : Int64?
    column average_score : Float64?
    column available_for_hire : Bool?
    has_one sign_in_credential : SignInCredential?
  end
end

class UserQuery < User::BaseQuery
end
