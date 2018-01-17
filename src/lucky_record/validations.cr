require "./validations/**"

module LuckyRecord::Validations
  private def validate_required(*fields, message = "is required")
    fields.each do |field|
      if field.value.blank?
        field.add_error message
      end
    end
  end

  private def validate_acceptance_of(field : AllowedField(Bool?) | Field(Bool?), message = "must be accepted")
    if field.value == false
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
end
