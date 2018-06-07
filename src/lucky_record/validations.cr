require "./validations/**"

module LuckyRecord::Validations
  private def validate_required(*fields, message = "is required")
    fields.each do |field|
      if field.value.blank?
        field.add_error message
      end
    end
  end

  private def validate_acceptance_of(field : FillableField(Bool?) | Field(Bool?), message = "must be accepted")
    if field.value != true
      field.add_error message
    end
  end

  private def validate_confirmation_of(field, with confirmation_field, message = "must match")
    if field.value != confirmation_field.value
      confirmation_field.add_error message
    end
  end

  private def validate_inclusion_of(field, in allowed_values, message = "is invalid")
    if !allowed_values.includes? field.value
      field.add_error message
    end
  end

  private def validate_size_of(field, *, is exact_size, message = "is invalid")
    if field.value.to_s.size != exact_size
      field.add_error message
    end
  end

  private def validate_size_of(field, min = nil, max = nil)
    if !min.nil? && !max.nil? && min > max
      raise ImpossibleValidation.new(field: field.name, message: "size greater than #{min} but less than #{max}")
    end

    size = field.value.to_s.size

    if !min.nil? && size < min
      field.add_error "is too short"
    end

    if !max.nil? && size > max
      field.add_error "is too long"
    end
  end

  private def validate_uniqueness_of(
    field : LuckyRecord::Field | LuckyRecord::FillableField,
    query : LuckyRecord::Criteria,
    message : String = "is already taken"
  )
    field.value.try do |value|
      if query.is(value).first?
        field.add_error message
      end
    end
  end

  private def validate_uniqueness_of(
    field : LuckyRecord::Field | LuckyRecord::FillableField,
    message : String = "is already taken"
  )
    field.value.try do |value|
      if build_validation_query(field.name, field.value).first?
        field.add_error message
      end
    end
  end

  # Must be included in the macro to get access to the generic T class
  # in forms that save to the database.
  #
  # VirtualForms will also have access to this, but will fail if you try to use
  # if because there is no T (model class).
  macro included
    private def build_validation_query(column_name, value) : T::BaseQuery
      T::BaseQuery.new.where(column_name, value)
    end
  end
end
