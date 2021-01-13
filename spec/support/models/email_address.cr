class EmailAddress < BaseModel
  table do
    column address : String
    belongs_to business : Business?
  end
end
