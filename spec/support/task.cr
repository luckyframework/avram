class Task < BaseModel
  table do
    column title : String
    column body : String?
  end
end
