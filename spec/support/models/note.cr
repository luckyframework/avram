class Note < BaseModel
  table do
    column from : String
    column read : Bool = false
    column text : String
  end
end

class NoteQuery < Note::BaseQuery
end
