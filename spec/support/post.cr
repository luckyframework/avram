require "./comment"

class Post < Avram::Model
  skip_default_columns

  table posts do
    primary_key custom_id : Int64
    timestamps

    column title : String
    column published_at : Time?
    has_many comments : Comment
    has_many taggings : Tagging
    has_many tags : Tag, through: :taggings
  end
end
