class Task < BaseModel
  table do
    column title : String
    column body : String?
    column completed_at : Time?
  end
end
