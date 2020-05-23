# A number of methods for validating Avram::Attributes that
# are specific to the database
#
# This module is included in `Avram::SaveOperation`
module Avram::DatabaseValidations
  # Validates that the given attribute is unique in the database
  #
  # > This will only work with attributes that correspond to a database column.
  #
  # ```
  # validate_uniqueness_of email
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
  def validate_uniqueness_of(
    attribute : Avram::Attribute,
    query : Avram::Criteria,
    message : String = "is already taken"
  )
    attribute.value.try do |value|
      if query.eq(value).first?
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
  def validate_uniqueness_of(
    attribute : Avram::Attribute,
    message : String = "is already taken"
  )
    attribute.value.try do |value|
      if build_validation_query(attribute.name, attribute.value).first?
        attribute.add_error message
      end
    end
  end

  # Must be included in the macro to get access to the generic T class
  # in forms that save to the database.
  #
  # Operations will also have access to this, but will fail if you try to use
  # if because there is no T (model class).
  macro included
    private def build_validation_query(column_name, value) : T::BaseQuery
      query = T::BaseQuery.new.where(column_name, value)
      record.try(&.id).try do |id|
        query = query.id.not.eq(id)
      end
      query
    end
  end
end
