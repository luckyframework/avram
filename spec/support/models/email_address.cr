class EmailAddress < BaseModel
  table do
    column address : String
    # This will test that we can update records that use keyword names
    column default : Bool
    belongs_to business : Business?
  end
end
