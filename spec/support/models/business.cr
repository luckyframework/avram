class Business < BaseModel
  table do
    column name : String
    has_one tax_id : TaxId
    has_one email_address : EmailAddress
  end
end

class TaxId < BaseModel
  table do
    column number : Int32
    belongs_to business : Business
  end
end

class EmailAddress < BaseModel
  table do
    column address : String
    belongs_to business : Business?
  end
end
