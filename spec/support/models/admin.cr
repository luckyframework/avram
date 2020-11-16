class Admin < BaseModel
  COLUMN_SQL = "admins.id, admins.created_at, admins.updated_at, admins.name"

  table do
    column name : String
    has_one sign_in_credential : SignInCredential, foreign_key: :user_id
  end
end

class AdminQuery < Admin::BaseQuery
end
