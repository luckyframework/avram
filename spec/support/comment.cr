class Comment < BaseModel
  skip_default_columns

  table do
    primary_key custom_id : Int64
    timestamps
    column body : String
    belongs_to post : Post
  end
end

class CommentForCustomPost < BaseModel
  skip_default_columns

  table :comments do
    primary_key custom_id : Int64
    timestamps
    column body : String
    belongs_to post_with_custom_table : PostWithCustomTable,
      table: :posts,
      foreign_key: :post_id
  end
end
