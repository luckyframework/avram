class EmailDomainRecord < BaseModel
  table do
    column verified : Bool = false
    belongs_to email_address : EmailAddress
  end
end
