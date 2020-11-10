class Manager < BaseModel
  table do
    column name : String
    has_many employees : Employee
  end
end
