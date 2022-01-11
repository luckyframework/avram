class Article < BaseModel
  COLUMN_SQL = "articles.id, articles.created_at, articles.updated_at, articles.title, articles.slug"

  table do
    column title : String
    column sub_heading : String?
    column slug : String
  end
end

class ArticleQuery < Article::BaseQuery
end
