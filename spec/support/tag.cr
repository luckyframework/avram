class Tag < LuckyRecord::Model
  table :tags do
    column name : String
    has_many taggings : Tagging
  end
end
