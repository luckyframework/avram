class Token < BaseModel
  table do
    column name : String = "Secret"
    column scopes : Array(String) = ["email"]
    column next_id : Int32 = 0
  end
end

class TokenQuery < Token::BaseQuery
end
