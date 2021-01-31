# Add methods for soft deleting and restoring an individual record
#
# Include this module in your model, and make sure to add a `soft_deleted_at`
# column to your model. The column type must be `Time?`
#
# ```
# # In a migration
# add soft_deleted_at : Time?
#
# # In your model
# class Article < BaseModel
#   include Avram::SoftDelete::Model

#   table do
#     column soft_deleted_at : Time?
#   end
# end
# ```
#
# You should also add the `Avram::SoftDeleteQuery` to your query
#
# ```
# class ArticleQuery < Article::BaseQuery
#   include Avram::SoftDelete::Query
# end
# ```
module Avram::SoftDelete::Model
  # Soft delete the record
  #
  # This will set `soft_deleted_at` to the current time (`Time.utc`)
  def soft_delete : self
    save_operation_class.update!(self, soft_deleted_at: Time.utc)
  end

  # Restore the record
  #
  # This will set `soft_deleted_at` to `nil`
  def restore : self
    save_operation_class.update!(self, soft_deleted_at: nil)
  end

  abstract def save_operation_class

  # Returns true if soft deleted, otherwise false
  #
  # If the `soft_deleted_at` has a time value the record is "soft deleted".
  # If `soft_deleted_at` is `nil` the record has not been deleted yet.
  def soft_deleted? : Bool
    soft_deleted_at.present?
  end

  abstract def soft_deleted_at : Time?
end
