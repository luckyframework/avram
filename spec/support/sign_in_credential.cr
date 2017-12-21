require "./user"

class SignInCredential < LuckyRecord::Model
  table :sign_in_credentials do
    belongs_to user : User
  end
end
