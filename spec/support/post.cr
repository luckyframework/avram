class Post < Avram::Model
  skip_default_columns

  table do
    primary_key custom_id : Int64
    timestamps

    column title : String
    column published_at : Time?
    has_many comments : Comment
    has_many taggings : Tagging
    has_many tags : Tag, through: :taggings
  end
end

# This is a regular post, but with a custom table name
# This is to test that 'belongs_to' can accept a 'table' in the
# CommentForCustomPost model
class PostWithCustomTable < Avram::Model
  skip_default_columns

  table :posts do
    primary_key custom_id : Int64
    timestamps

    column title : String
    column published_at : Time?
  end
end
