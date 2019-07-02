require "./post"

class Comment < Avram::Model
  skip_default_columns

  table do
    primary_key custom_id : Int64
    timestamps
    column body : String
    belongs_to post : Post
  end
end
