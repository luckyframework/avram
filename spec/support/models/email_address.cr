class EmailAddress < BaseModel
  table do
    column address : String
    # This will test that we can update records that use keyword names
    column default : Bool = true
    belongs_to business : Business?
  end
end
