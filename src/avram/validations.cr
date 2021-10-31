require "./validations/callable_error_message"

# A number of methods for validating Avram::Attributes
# All validation methods return `Bool`. `false` if any error is added, otherwise `true`
#
# This module is included in `Avram::Operation`, `Avram::SaveOperation`, and `Avram::DeleteOperation`
module Avram::Validations
  extend self

  macro included
    abstract def default_validations
  end

  # Defines an instance method that gets called
  # during validation of an operation. Define your default
  # validations inside of the block.
  # ```
  # default_validations do
  #   validate_required some_attribute
  # end
  # ```
  macro default_validations
    # :nodoc:
    def default_validations
      {% if @type.methods.map(&.name).includes?(:default_validations.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {{ yield }}
    end
  end

  # Validates that at most one attribute is filled
  #
  # If more than one attribute is filled it will mark all but the first filled
  # field invalid.
  def validate_at_most_one_filled(
    *attributes,
    message : Avram::Attribute::ErrorMessage = Avram.settings.i18n_backend.get(:validate_at_most_one_filled)
  ) : Bool
    no_errors = true
    present_attributes = attributes.reject(&.value.blank?)

    if present_attributes.size > 1
      present_attributes.skip(1).each do |attr|
        attr.add_error(message)
        no_errors = false
      end
    end

    no_errors
  end

  # Validates that at exactly one attribute is filled
  #
  # This validation is used by `Avram::Polymorphic.polymorphic` to ensure
  # that a required polymorphic association is set.
  #
  # If more than one attribute is filled it will mark all but the first filled
  # field invalid.
  #
  # If no field is filled, the first field will be marked as invalid.
  def validate_exactly_one_filled(
    *attributes,
    message : Avram::Attribute::ErrorMessage = Avram.settings.i18n_backend.get(:validate_exactly_one_filled)
  ) : Bool
    no_errors = validate_at_most_one_filled(*attributes)
    present_attributes = attributes.reject(&.value.blank?)

    if present_attributes.size.zero?
      attributes.first.add_error(message)
      no_errors = false
    end

    no_errors
  end

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
  def validate_required(
    *attributes,
    message : Avram::Attribute::ErrorMessage = Avram.settings.i18n_backend.get(:validate_required)
  ) : Bool
    no_errors = true
    attributes.each do |attribute|
      if attribute.value.blank_for_validates_required?
        attribute.add_error(message)
        no_errors = false
      end
    end

    no_errors
  end

  # Validate whether an attribute was accepted (`true`)
  #
  # This validation is only for Boolean Attributes. The attribute will be marked
  # as invalid for any value other than `true`.
  def validate_acceptance_of(
    attribute : Avram::Attribute(Bool),
    message : Avram::Attribute::ErrorMessage = Avram.settings.i18n_backend.get(:validate_acceptance_of)
  ) : Bool
    no_errors = true
    if attribute.value != true
      attribute.add_error(message)
      no_errors = false
    end

    no_errors
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
    message : Avram::Attribute::ErrorMessage = Avram.settings.i18n_backend.get(:validate_confirmation_of)
  ) : Bool forall T
    no_errors = true
    if attribute.value != confirmation_attribute.value
      confirmation_attribute.add_error(message)
      no_errors = false
    end

    no_errors
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
    message : Avram::Attribute::ErrorMessage = Avram.settings.i18n_backend.get(:validate_inclusion_of),
    allow_nil : Bool = false
  ) : Bool forall T
    no_errors = true
    if !allowed_values.includes?(attribute.value)
      if !(allow_nil && attribute.value.nil?)
        attribute.add_error(message)
        no_errors = false
      end
    end

    no_errors
  end

  # Validate the size of a `String` is exactly a certain size
  #
  # ```
  # validate_size_of api_key, is: 32
  # ```
  def validate_size_of(
    attribute : Avram::Attribute(String),
    *,
    is exact_size,
    message : Avram::Attribute::ErrorMessage = Avram.settings.i18n_backend.get(:validate_exact_size_of),
    allow_nil : Bool = false
  ) : Bool
    no_errors = true
    if attribute.value.to_s.size != exact_size
      if !(allow_nil && attribute.value.nil?)
        attribute.add_error(message % exact_size)
        no_errors = false
      end
    end

    no_errors
  end

  # Validate the size of a `String` is within a `min` and/or `max`
  #
  # ```
  # validate_size_of feedback, min: 18, max: 100
  # validate_size_of password, min: 12
  # ```
  # ameba:disable Metrics/CyclomaticComplexity
  def validate_size_of(
    attribute : Avram::Attribute(String),
    min = nil,
    max = nil,
    message : Avram::Attribute::ErrorMessage? = nil,
    allow_nil : Bool = false
  ) : Bool
    no_errors = true
    if !min.nil? && !max.nil? && min > max
      raise ImpossibleValidation.new(
        attribute: attribute.name,
        message: "size greater than #{min} but less than #{max}")
    end

    unless allow_nil && attribute.value.nil?
      size = attribute.value.to_s.size

      if !min.nil? && size < min
        attribute.add_error(
          (message || Avram.settings.i18n_backend.get(:validate_min_size_of)) % min
        )
        no_errors = false
      end

      if !max.nil? && size > max
        attribute.add_error(
          (message || Avram.settings.i18n_backend.get(:validate_max_size_of)) % max
        )
        no_errors = false
      end
    end

    no_errors
  end

  # Validate a number is `greater_than` and/or `less_than`
  #
  # ```
  # validate_numeric age, greater_than: 18
  # validate_numeric count, greater_than: 0, less_than: 1200
  # ```
  # ameba:disable Metrics/CyclomaticComplexity
  def validate_numeric(
    attribute : Avram::Attribute(Number),
    greater_than = nil,
    less_than = nil,
    message = nil,
    allow_nil : Bool = false
  ) : Bool
    no_errors = true
    if greater_than && less_than && greater_than > less_than
      raise ImpossibleValidation.new(
        attribute: attribute.name,
        message: "number greater than #{greater_than} but less than #{less_than}")
    end

    number = attribute.value

    if number.nil?
      unless allow_nil
        attribute.add_error(
          Avram.settings.i18n_backend.get(:validate_numeric_nil)
        )
        no_errors = false
      end
      return no_errors
    end

    if greater_than && number < greater_than
      attribute.add_error(
        (message || Avram.settings.i18n_backend.get(:validate_numeric_min)) % greater_than
      )
      no_errors = false
    end

    if less_than && number > less_than
      attribute.add_error(
        (message || Avram.settings.i18n_backend.get(:validate_numeric_max)) % less_than
      )
      no_errors = false
    end

    no_errors
  end

  # Validates that the passed in attributes matches the given regex
  #
  # ```
  # validate_format_of email, with: /[^@]+@[^\.]+\..+/
  # ```
  #
  # Alternatively, the `match` argument can be set to `false` to not match the
  # given regex.
  def validate_format_of(
    attribute : Avram::Attribute(String),
    with regex : Regex,
    match : Bool = true,
    message : Avram::Attribute::ErrorMessage = "is invalid",
    allow_nil : Bool = false
  ) : Bool
    unless allow_nil && attribute.value.nil?
      matching = attribute.value.to_s.match(regex)

      if (match && !matching) || (!match && matching)
        attribute.add_error(message)
        return false
      end
    end

    true
  end
end
