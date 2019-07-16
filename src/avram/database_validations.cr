require "./validations/**"

module Avram::DatabaseValidations
  private def validate_uniqueness_of(
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

  private def validate_uniqueness_of(
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
