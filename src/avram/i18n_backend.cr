abstract struct Avram::I18nBackend
  abstract def get(key : String | Symbol) : String
end

struct Avram::I18n < Avram::I18nBackend
  def get(key : String | Symbol) : String
    {
      validate_acceptance_of:      "must be accepted",
      validate_at_most_one_filled: "must be blank",
      validate_confirmation_of:    "must match",
      validate_exact_size_of:      "must be exactly %d characters long",
      validate_exactly_one_filled: "at least one must be filled",
      validate_format_of:          "is invalid",
      validate_inclusion_of:       "is not included in the list",
      validate_max_size_of:        "must not have more than %d characters",
      validate_min_size_of:        "must have at least %d characters",
      validate_numeric_max:        "must be no more than %d",
      validate_numeric_min:        "must be at least %d",
      validate_numeric_nil:        "must not be nil",
      validate_required:           "is required",
      validate_uniqueness_of:      "is already taken",
    }[key]
  end
end
