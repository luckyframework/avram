class CommentReaction < BaseModel
  table do
    column emoji : String
    belongs_to comment : Comment
  end
end
