class Task < Avram::Model
  table do
    column title : String
    column body : String?
  end
end
