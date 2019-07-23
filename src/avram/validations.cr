require "./validations/callable_error_message"

module Avram::Validations
  extend self

  def validate_required(*attributes, message : Avram::Attribute::ErrorMessage = "is required")
    attributes.each do |attribute|
      if attribute.value.blank? && attribute.value != false
        attribute.add_error message
      end
    end
  end

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

  def validate_inclusion_of(
    attribute : Avram::Attribute(T),
    in allowed_values : Enumerable(T),
    message : Avram::Attribute::ErrorMessage = "is invalid"
  ) forall T
    if !allowed_values.includes? attribute.value
      attribute.add_error message
    end
  end

  def validate_size_of(attribute : Avram::Attribute, *, is exact_size, message : Avram::Attribute::ErrorMessage = "is invalid")
    if attribute.value.to_s.size != exact_size
      attribute.add_error message
    end
  end

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
