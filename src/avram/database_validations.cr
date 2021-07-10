require "./validations/**"

module Avram::DatabaseValidations(T)
  # Validates that the given attribute is unique in the database
  #
  # > This will only work with attributes that correspond to a database column.
  #
  # Passing a criteria is useful when wanting to change how it compares the value in the database.
  # For example, making sure that it compares emails that are all downcased to account for different capital letters.
  #
  # ```
  # validate_uniqueness_of email, query: UserQuery.new.email.lower
  # ```
  #
  # If there is another email address with the same value, the attribute will be
  # marked as invalid.
  #
  # Note that you should also add a unique index when creating the table so that
  # there are no race conditions and you are guaranteed that the value is unique.
  #
  # This validation is still useful as it will check for uniqueness along with
  # all other validations. If you just have the uniqueness constraint in the
  # database you will not know if there is a collision until all other validations
  # pass and Avram tries to save the record.
  private def validate_uniqueness_of(
    attribute : Avram::Attribute,
    query : Avram::Criteria(T::BaseQuery, _),
    message : String = "is already taken"
  )
    attribute.value.try do |value|
      if limit_query(query.eq(value)).any?
        attribute.add_error message
      end
    end
  end

  # Validates that the given attribute is unique in the database with a custom query
  #
  # The principle is the same as the other `validate_uniqueness_of` method, but
  # this one allows customizing the query.
  #
  # This is especially helpful when you want to scope the uniqueness to a subset
  # of records.
  #
  # For example, if you want to check that a username is unique within a company:
  #
  # ```
  # validate_uniqueness_of username, query: UserQuery.new.company_id(123)
  # ```
  #
  # So if there is the same username in other companies, this validation will
  # still pass.
  #
  # Note that you should also add a unique validation constraint in the database
  # This can be done using Avram migrations. For example:
  #
  # ```
  # add_index [:username, :company_id], unique: true
  # ```
  private def validate_uniqueness_of(
    attribute : Avram::Attribute,
    query : T::BaseQuery,
    message : String = "is already taken"
  )
    attribute.value.try do |value|
      if limit_query(query).where(attribute.name, value).any?
        attribute.add_error message
      end
    end
  end

  # Validates that the given attribute is unique in the database
  #
  # > This will only work with attributes that correspond to a database column.
  #
  # ```
  # validate_uniqueness_of name
  # ```
  #
  # If there is another database row with the same name, the attribute will be
  # marked as invalid.
  #
  # Note that you should also add a unique index when creating the table so that
  # there are no race conditions and you are guaranteed that the value is unique.
  #
  # This validation is still useful as it will check for uniqueness along with
  # all other validations. If you just have the uniqueness constraint in the
  # database you will not know if there is a collision until all other validations
  # pass and Avram tries to save the record.
  private def validate_uniqueness_of(
    attribute : Avram::Attribute,
    message : Avram::Attribute::ErrorMessage = "is already taken"
  )
    validate_uniqueness_of(attribute: attribute, query: T::BaseQuery.new, message: message)
  end

  private def limit_query(query)
    record.try(&.id).try do |id|
      query = query.id.not.eq(id)
    end
    query
  end
end
