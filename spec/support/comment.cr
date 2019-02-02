require "./post"

class Comment < Avram::Model
  table comments do
    column body : String
    belongs_to post : Post
  end
end
