class Tag < Avram::Model
  table do
    column name : String
    has_many taggings : Tagging
  end
end
