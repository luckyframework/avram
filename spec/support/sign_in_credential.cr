require "./user"

class SignInCredential < Avram::Model
  table :sign_in_credentials do
    belongs_to user : User
  end
end
