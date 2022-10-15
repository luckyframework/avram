class Token < BaseModel
  table do
    column name : String = "Secret"
    column scopes : Array(String) = ["email"]
  end
end

class TokenQuery < Token::BaseQuery
end
