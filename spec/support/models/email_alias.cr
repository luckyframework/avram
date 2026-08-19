class EmailAlias < BaseModel
  table do
    column address : String
    belongs_to email_address : EmailAddress
  end
end
