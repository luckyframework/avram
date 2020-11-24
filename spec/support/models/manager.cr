class Manager < BaseModel
  table do
    column name : String
    has_many employees : Employee
    has_many customers : Customer, through: [:employees, :customers]
  end
end
