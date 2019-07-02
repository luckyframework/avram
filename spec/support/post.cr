require "./comment"

class Post < Avram::Model
  table do
    column title : String
    column published_at : Time?
    has_many comments : Comment
    has_many taggings : Tagging
    has_many tags : Tag, through: :taggings
  end
end
