require "./post"

class Comment < LuckyRecord::Model
  table comments do
    column body : String
    belongs_to post : Post
  end
end
