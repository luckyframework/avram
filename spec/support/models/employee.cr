class Employee < BaseModel
  table do
    column name : String
    belongs_to manager : Manager?
    has_many customers : Customer
  end
end
