module LuckyRecord::Validations
  private def validate_required(*fields)
    fields.each do |field|
      if field.value.blank?
        field.add_error "is required"
      end
    end
  end
end
