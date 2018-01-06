require "./employee"

class Manager < LuckyRecord::Model
  table managers do
    column name : String
    has_many employees : Employee
  end
end
