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
#
# The `set` method will use `query` to determine if that `slug` has already
# been used, and fall back to appending a random UUID to the end. If the `slug`
# value has already been set, then no new slug will be generated. If you just need
# the value to set on your own, you can use the `generate` method as an escape hatch.
# This method returns the String value used in the `set` method.
#
# ```
# class SaveArticle < Article::SaveOperation
#   before_save do
#     if title.changed?
#       slug_value = Avram::Slugify.generate(slug,
#         using: title,
#         query: ArticleQuery.new)
#       slug.value = slug_value
#     end
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
      slug.value = generate(slug, slug_candidates, query)
    end
  end

  def generate(slug : Avram::Attribute(String),
               using slug_candidate : Avram::Attribute(String) | String,
               query : Avram::Queryable) : String?
    generate(slug, [slug_candidate], query)
  end

  def generate(slug : Avram::Attribute(String),
               using slug_candidates : Array(String | Avram::Attribute(String) | Array(Avram::Attribute(String))),
               query : Avram::Queryable) : String?
    slug_candidates = format_candidates(slug_candidates)

    result = slug_candidates.find { |candidate|
      query.where(slug.name, candidate).none?
    }

    if result
      result
    elsif candidate = slug_candidates.first?
      "#{candidate}-#{UUID.random}"
    end
  end

  private def format_candidates(slug_candidates : Array(String | Avram::Attribute(String) | Array(Avram::Attribute(String)))) : Array(String)
    slug_candidates.map do |candidate|
      parameterize(candidate)
    end.reject(&.blank?)
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
