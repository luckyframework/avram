require "./manager"

class Employee < LuckyRecord::Model
  table employees do
    column name : String
    belongs_to manager : Manager?
  end
end
