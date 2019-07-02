class Tagging < Avram::Model
  table do
    belongs_to tag : Tag
    belongs_to post : Post
  end
end
