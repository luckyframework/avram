class SignInCredential < BaseModel
  table do
    belongs_to user : User
  end
end
