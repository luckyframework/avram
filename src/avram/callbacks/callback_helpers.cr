module Avram::CallbackHelpers
  # :nodoc:
  macro conditional_error_for_inline_callbacks(callback, method_name, condition)
    \{%
      raise <<-ERROR
      You must pass a Symbol to `{{ condition.id }}` in {{ @type }}. The Symbol will reference a method you define.

      Try this...

        {{ callback.id }} {{ method_name.id }}, {{ condition.id }}: :check_condition?

        def check_condition?
          # return your bool value here
        end
      ERROR
    %}
  end

  macro conditional_error_for_block_callbacks(callback, condition)
    \{%
    raise <<-ERROR
    You must pass a Symbol to `{{ condition.id }}` in {{ @type }}. The Symbol will reference a method you define.

    Try this...

      {{ callback.id }}({{ condition.id }}: :check_condition?) do
        # your callback block
      end

      def check_condition?
        # return your bool value here
      end
    ERROR
  %}
  end
end
