class BusinessSale < BaseModel
  table do
    column name : String
    belongs_to employee : Employee
    has_many managers : Manager, through: :employee
  end
end
