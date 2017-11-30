require "./post"

class Employee < LuckyRecord::Model
  table employees do
    field name : String
    belongs_to manager : Manager?
  end
end
