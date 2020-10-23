class Manager < BaseModel
  table do
    column name : String
    has_many employees : Employee
    has_many business_sales : BusinessSale, through: :employees
  end
end
