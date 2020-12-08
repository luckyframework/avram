class NicknameInfo < BaseModel
  view do
    column nickname : String
    column count : Int64
  end
end
