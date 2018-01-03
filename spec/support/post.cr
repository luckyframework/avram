require "./comment"

class Post < LuckyRecord::Model
  table posts do
    field title : String
    field published_at : Time?
    has_many comments : Comment
  end
end
