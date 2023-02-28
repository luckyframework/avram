module Avram::PrimaryKeyMethods
  def_equals id, model_name

  def primary_key_name : Symbol?
    self.class.primary_key_name
  end

  # Reload the model with the latest information from the database
  #
  # This method will return a new model instance with the
  # latest data from the database. Note that this does
  # **not** change the original instance, so you may need to
  # assign the result to a variable or work directly with the return value.
  #
  # Example:
  #
  # ```
  # user = SaveUser.create!(name: "Original")
  # SaveUser.update!(user, name: "Updated")
  #
  # # Will be "Original"
  # user.name
  # # Will return "Updated"
  # user.reload.name # Will be "Updated"
  # # Will still be "Original" since the 'user' is the same model instance.
  # user.name
  #
  # Instead re-assign the variable. Now 'name' will return "Updated" since
  # 'user' references the reloaded model.
  # user = user.reload
  # user.name
  # ```
  def reload : self
    base_query_class.find(id)
  end

  # Same as `reload` but allows passing a block to customize the query.
  #
  # This is almost always used to preload additional relationships.
  #
  # Example:
  #
  # ```
  # user = SaveUser.create(params)
  #
  # # We want to display the list of articles the user has commented on, so let's #
  # # preload them to avoid N+1 performance issues
  # user = user.reload(&.preload_comments(CommentQuery.new.preload_article))
  #
  # # Now we can safely get all the comment authors
  # user.comments.map(&.article)
  # ```
  #
  # Note that the yielded query is the `BaseQuery` so it will not have any
  # methods defined on your customized query. This is usually fine since
  # typically reload only uses preloads.
  #
  # If you do need to do something more custom you can manually reload:
  #
  # ```
  # user = SaveUser.create!(name: "Helen")
  # UserQuery.new.some_custom_preload_method.find(user.id)
  # ```
  def reload(&) : self
    query = yield base_query_class.new
    query.find(id)
  end

  # For integration with Lucky
  # This allows an `Avram::Model` to be passed into a Lucky::Action to create a url/path
  def to_param : String
    id.to_s
  end

  def delete
    self.class.database.exec "DELETE FROM #{@@table_name} WHERE #{primary_key_name} = #{escape_primary_key(id)}"
  end

  private def escape_primary_key(id : Int64 | Int32 | Int16)
    id
  end

  private def escape_primary_key(id : UUID)
    PG::EscapeHelper.escape_literal(id.to_s)
  end
end
