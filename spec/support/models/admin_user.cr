# an AdminUser is a User who's name is also found in the Admin table
class AdminUser < BaseModel
  view do
    primary_key id : Int64
    timestamps
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
