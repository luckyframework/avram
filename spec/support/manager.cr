class Manager < Avram::Model
  table do
    column name : String
    has_many employees : Employee
  end
end
