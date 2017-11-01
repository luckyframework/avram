require "./comment"

class Post < LuckyRecord::Model
  table :posts do
    field title : String
    has_many comments : Comment
  end
end
