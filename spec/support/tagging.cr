class Tagging < Avram::Model
  table :taggings do
    belongs_to tag : Tag
    belongs_to post : Post
  end
end
