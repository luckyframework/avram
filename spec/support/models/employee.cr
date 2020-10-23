class Employee < BaseModel
  table do
    column name : String
    belongs_to manager : Manager?
    has_many business_sales : BusinessSale
  end
end
