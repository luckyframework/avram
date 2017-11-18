module LuckyRecord::Validations
  private def validate_required(*fields)
    fields.each do |field|
      if field.value.blank?
        field.add_error "is required"
      end
    end
  end

  private def validate_acceptance_of(field : LuckyRecord::Field(Bool))
    if field.value == false
      field.add_error "must be accepted"
    end
  end

  private def validate_confirmation_of(field, with confirmation_field)
    if field.value != confirmation_field.value
      confirmation_field.add_error "must match"
    end
  end

  private def validate_inclusion_of(field, in allowed_values)
    if !allowed_values.includes? field.value
      field.add_error "is invalid"
    end
  end
end
