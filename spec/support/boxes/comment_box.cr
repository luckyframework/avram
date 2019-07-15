class CommentBox < BaseBox
  def initialize
    body "Best comment ever"
    commentable_id 1
    commentable_type "Company"
  end
end
