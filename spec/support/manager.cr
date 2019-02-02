require "./employee"

class Manager < Avram::Model
  table managers do
    column name : String
    has_many employees : Employee
  end
end
