class Business < BaseModel
  table do
    column name : String
    column latitude : Float64?
    column longitude : Float64?
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
