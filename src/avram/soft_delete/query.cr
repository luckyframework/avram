# Add methods for querying/updating soft deleted and kept records.
#
# First include the model module in your model: `Avram::SoftDelete::Model`
#
# Then add this module your query
#
# ```
# class ArticleQuery < Article::BaseQuery
#   include Avram::SoftDelete::Query
# end
# ```
module Avram::SoftDelete::Query
  # Only return kept records
  #
  # Kept records are considered "kept/not soft deleted" if the
  # `soft_deleted_at` column is `nil`
  def only_kept
    reset_where(&.soft_deleted_at).soft_deleted_at.is_nil
  end

  # Only return soft deleted records
  #
  # Soft deleted records are considered "soft deleted" if the
  # `soft_deleted_at` column has a non-nil value
  def only_soft_deleted
    reset_where(&.soft_deleted_at).soft_deleted_at.is_not_nil
  end

  # Returns all records
  #
  # This works be removing where clauses for the `soft_deleted_at` column.
  # That means you can do `MyQuery.new.only_kept.with_soft_deleted` and you
  # will get all records, not just the kept ones.
  def with_soft_deleted
    reset_where(&.soft_deleted_at)
  end

  # Bulk soft delete records
  #
  # ## Example
  #
  # This will soft delete all `Article` record older than 1 year:
  #
  # ```
  # ArticleQuery.new.created_at.lt(1.year.ago).soft_delete
  # ```
  def soft_delete
    only_kept.update(soft_deleted_at: Time.utc)
  end

  # Bulk restore records
  #
  # ## Example
  #
  # This will restore `Article` records updated in the last week:
  #
  # ```
  # ArticleQuery.new.updated_at.gt(1.week.ago).restore
  # ```
  def restore : Int64
    only_soft_deleted.update(soft_deleted_at: nil)
  end

  abstract def soft_deleted_at
end
