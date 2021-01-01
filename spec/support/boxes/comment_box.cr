class CommentBox < BaseBox
  def initialize
    body "Best comment ever"
  end

  def nice
    body Comment::NICE_COMMENT_BODY
  end
end
