require "./employee"

class Manager < LuckyRecord::Model
  table managers do
    field name : String
    has_many employees : Employee
  end
end
