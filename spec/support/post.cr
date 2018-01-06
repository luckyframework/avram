require "./comment"

class Post < LuckyRecord::Model
  table posts do
    column title : String
    column published_at : Time?
    has_many comments : Comment
  end
end
