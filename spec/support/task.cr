class Task < Avram::Model
  table tasks do
    column title : String
    column body : String?
  end
end
