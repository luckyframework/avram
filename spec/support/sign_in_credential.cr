class SignInCredential < Avram::Model
  table do
    belongs_to user : User
  end
end
