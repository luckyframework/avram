class Tagging < BaseModel
  skip_default_columns

  table do
    primary_key custom_id : Int64
    timestamps
    belongs_to tag : Tag
    belongs_to post : Post
  end
end
