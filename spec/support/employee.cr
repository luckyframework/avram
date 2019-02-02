require "./manager"

class Employee < Avram::Model
  table employees do
    column name : String
    belongs_to manager : Manager?
  end
end
