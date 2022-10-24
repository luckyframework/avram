class SignInCredential < BaseModel
  table do
    column value : String

    belongs_to user : User
  end
end
