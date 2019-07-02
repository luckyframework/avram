require "./post"

class Comment < Avram::Model
  table do
    column body : String
    belongs_to post : Post
  end
end
