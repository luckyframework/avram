class Business < Avram::Model
  table do
    column name : String
    has_one tax_id : TaxId
    has_one email_address : EmailAddress
  end
end

class TaxId < Avram::Model
  table do
    column number : Int32
    belongs_to business : Business
  end
end

class EmailAddress < Avram::Model
  table do
    column address : String
    belongs_to business : Business?
  end
end
