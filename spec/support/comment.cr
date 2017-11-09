require "./post"

class Comment < LuckyRecord::Model
  table comments do
    field body : String
    belongs_to post : Post
  end
end
