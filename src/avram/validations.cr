require "./validations/callable_error_message"

# A number of methods for validating Avram::Attributes
#
# This module is included in `Avram::Operation` and `Avram::SaveOperation`
module Avram::Validations
  extend self

  # Validates that the passed in attributes have values
  #
  # You can pass in one or more attributes at a time. The attribute will be
  # marked as invalid if the value is `nil`, or "blank" (empty strings or strings with just whitespace)
  #
  # `false` is not considered invalid.
  #
  # ```
  # validate_required name, age, email
  # ```
  def validate_required(*attributes, message : Avram::Attribute::ErrorMessage = "is required")
    attributes.each do |attribute|
      if attribute.value.blank? && attribute.value != false
        attribute.add_error message
      end
    end
  end

  # Validate whether an attribute was accepted (`true`)
  #
  # This validation is only for Boolean Attributes. The attribute qill be marked
  # as invalid for any value other than `true`.
  def validate_acceptance_of(attribute : Avram::Attribute(Bool?), message : Avram::Attribute::ErrorMessage = "must be accepted")
    if attribute.value != true
      attribute.add_error message
    end
  end

  # Validates that the values of two attributes are the same
  #
  # Takes two attributes and if the values are different the second attribute
  # (`with`/`confirmation_attribute`) will be marked as invalid
  #
  # Example:
  #
  # ```
  # validate_confirmation_of password, with: password_confirmation
  # ```
  #
  # If `password_confirmation` does not match, it will be marked invalid.
  def validate_confirmation_of(
    attribute : Avram::Attribute(T),
    with confirmation_attribute : Avram::Attribute(T),
    message : Avram::Attribute::ErrorMessage = "must match"
  ) forall T
    if attribute.value != confirmation_attribute.value
      confirmation_attribute.add_error message
    end
  end

  # Validates that the attribute value is in a list of allowed values
  #
  # ```
  # validate_inclusion_of state, in: ["NY", "MA"]
  # ```
  #
  # This will mark `state` as invalid unless the value is `"NY"`, or `"MA"`.
  def validate_inclusion_of(
    attribute : Avram::Attribute(T),
    in allowed_values : Enumerable(T),
    message : Avram::Attribute::ErrorMessage = "is invalid"
  ) forall T
    if !allowed_values.includes? attribute.value
      attribute.add_error message
    end
  end

  # Validate the size of a `String` is exactly a certain size
  #
  # ```
  # validate_size_of api_key, is: 32
  # ```
  def validate_size_of(attribute : Avram::Attribute, *, is exact_size, message : Avram::Attribute::ErrorMessage = "is invalid")
    if attribute.value.to_s.size != exact_size
      attribute.add_error message
    end
  end

  # Validate the size of the attribute is within a `min` and/or `max`
  #
  # ```
  # validate_size_of age, min: 18, max: 100
  # validate_size_of account_balance, min: 500
  # ```
  def validate_size_of(attribute : Avram::Attribute, min = nil, max = nil)
    if !min.nil? && !max.nil? && min > max
      raise ImpossibleValidation.new(attribute: attribute.name, message: "size greater than #{min} but less than #{max}")
    end

    size = attribute.value.to_s.size

    if !min.nil? && size < min
      attribute.add_error "is too short"
    end

    if !max.nil? && size > max
      attribute.add_error "is too long"
    end
  end

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
    message : Avram::Attribute::ErrorMessage = "is already taken"
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
