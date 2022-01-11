# Converts a column value to a URL safe String that
# can be used as a parameter for finding records. A
# `slug` is a `String` column you define on your model
# that will be passed through the URL instead of an `id`.
#
# e.g. /articles/1 -> /articles/how-to-slugify
#
# Use this module in your `SaveOperation#before_save`.
#
# ```
# class Article < BaseModel
#   table do
#     column title : String
#     column slug : String
#   end
# end
#
# class SaveArticle < Article::SaveOperation
#   before_save do
#     Avram::Slugify.set slug,
#       using: title,
#       query: ArticleQuery.new
#   end
# end
# ```
module Avram::Slugify
  extend self

  def set(slug : Avram::Attribute(String),
          using slug_candidate : Avram::Attribute(String) | String,
          query : Avram::Queryable) : Nil
    set(slug, [slug_candidate], query)
  end

  def set(slug : Avram::Attribute(String),
          using slug_candidates : Array(String | Avram::Attribute(String) | Array(Avram::Attribute(String))),
          query : Avram::Queryable) : Nil
    if slug.value.blank?
      slug_candidates = slug_candidates.map do |candidate|
        parameterize(candidate)
      end.reject(&.blank?)

      slug_candidates.find { |candidate| query.where(slug.name, candidate).none? }
        .tap { |candidate| slug.value = candidate }
    end

    if slug.value.blank? && (candidate = slug_candidates.first?)
      slug.value = "#{candidate}-#{UUID.random}"
    end
  end

  private def parameterize(value : String) : String
    Cadmium::Transliterator.parameterize(value)
  end

  private def parameterize(value : Avram::Attribute(String)) : String
    parameterize(value.value.to_s)
  end

  private def parameterize(values : Array(Avram::Attribute(String))) : String
    values.join("-") { |value| parameterize(value) }
  end
end
