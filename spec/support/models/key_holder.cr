class KeyHolder < BaseModel
  table :users do
    has_many sign_in_credentials : SignInCredential, foreign_key: :user_id
  end
end

class KeyHolderQuery < KeyHolder::BaseQuery
end
