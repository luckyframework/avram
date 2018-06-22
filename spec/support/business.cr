class Business < LuckyRecord::Model
  table businesses do
    column name : String
    has_one tax_id : TaxId
    has_one email_address : EmailAddress
  end
end

class TaxId < LuckyRecord::Model
  table tax_ids do
    column number : Int32
    belongs_to business : Business
  end
end

class EmailAddress < LuckyRecord::Model
  table email_addresses do
    column address : String
    belongs_to business : Business?
  end
end
