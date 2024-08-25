class Note < BaseModel
  table do
    column from : String
    column read : Bool = false
    column text : String
    column order : Int32
  end
end

class NoteQuery < Note::BaseQuery
end
