# :nodoc:
#
# Shared `id=`/`name=` generation logic for `Avram::PermittedAttribute`
# fields, used by both `Lucky::InputHelpers` and `Lucky::SelectHelpers` so
# the two don't drift out of sync.
module Lucky::FieldKeyHelpers
  private property array_id_counter : Hash(Symbol, Int32) do
    Hash(Symbol, Int32).new { |hash, key| hash[key] = 0 }
  end

  # The `name=` value must be the *exact*, raw computed `param_key`
  # (e.g. `"comments[0]"`, `"comments[0]:comment_reaction"`) since that's
  # exactly what `Avram::Params`/`Lucky::Params` already know how to
  # decode back into a (possibly deeply nested) operation on submission.
  private def input_name(field : Avram::PermittedAttribute)
    "#{field.param_key}:#{field.name}"
  end

  private def input_name(field : Avram::PermittedAttribute(Array))
    "#{field.param_key}:#{field.name}[]"
  end

  private def input_id(field : Avram::PermittedAttribute)
    "#{sanitized_param_key(field)}_#{field.name}"
  end

  private def input_id(field : Avram::PermittedAttribute(Array))
    "#{sanitized_param_key(field)}_#{field.name}_#{array_id_counter[field.name]}"
  end

  # Unlike `name=`, the `id=` attribute doesn't need to round-trip
  # through parsing, so brackets/colons that a nested (`has_one`/
  # `has_many`) `param_key` may contain (e.g. `"comments[0]"`) are
  # collapsed into a single underscore. This keeps generated ids simple
  # and CSS-selector-safe, since brackets/colons are awkward for
  # `document.querySelector`/CSS even though they're technically legal in
  # an (escaped) HTML id.
  private def sanitized_param_key(field : Avram::PermittedAttribute) : String
    field.param_key.gsub(/[\[\]:]+/, "_").strip('_')
  end
end
