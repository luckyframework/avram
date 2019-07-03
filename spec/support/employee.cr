class Employee < Avram::Model
  table do
    column name : String
    belongs_to manager : Manager?
  end
end
