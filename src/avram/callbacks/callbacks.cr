module Avram::Callbacks
  # Run the given method before `run` is called on an `Operation`.
  #
  # Examples:
  #
  #   before_run :validate_inputs
  #
  #   before_run :validate_inputs, if: :should_validate?
  #   before_run :validate_inputs, unless: :skip_validation?
  #
  # private def validate_inputs
  #   validate_required data
  # end
  macro before_run(method_name, if _if = nil, unless _unless = nil)
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:before_run, {{ method_name }}, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:before_run, {{ method_name }}, :unless)
    {% end %}
    before_run(if: {{ _if }}, unless: {{ _unless }}) do
      {{ method_name.id }}
    end
  end

  # Run the given block before `run` is called on an `Operation`.
  #
  # This runs before `run` is invoked on the operation.
  # You can set defaults, validate, or perform any other setup necessary before running the operation.
  #
  # Optionally you can pass an `if` or `unless` argument which allows you to
  # run this conditionally. The symbol should reference a method you've defined
  # that returns a truthy/falsey value.
  #
  # ```
  # before_run(unless: :skip_callback?) do
  #   validate_required data
  # end
  #
  # private def skip_callback?
  #   false
  # end
  # ```
  macro before_run(if _if = nil, unless _unless = nil)
    {% if _if != nil && _unless != nil %}
      {% raise "Your before_run callbacks should only specify `if` or `unless`, but not both." %}
    {% end %}
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:before_run, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:before_run, :unless)
    {% end %}

    def before_run : Nil
      {% if @type.methods.map(&.name).includes?(:before_run.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {% if _if %}
      if {{ _if.id }}
        {{ yield }}
      end
      {% elsif _unless %}
      unless {{ _unless.id }}
        {{ yield }}
      end
      {% else %}
        {{ yield }}
      {% end %}
    end
  end

  # Run the given method after `run` is called on an `Operation`.
  # The return value of the `run` method is passed to `method_name`.
  #
  # ```
  # after_run :log_entry
  #
  # private def log_entry(value)
  #   log_stuff(value)
  # end
  # ```
  macro after_run(method_name)
    after_run do |object|
      {{ method_name.id }}(object)
    end
  end

  # Run the given block after the operation runs
  #
  # The return value from `run` will be passed to this block.
  #
  # ```
  # class GenerateReport < Avram::Operation
  #   after_run do |value|
  #     value == "some report"
  #   end
  #
  #   def run
  #     "some report"
  #   end
  # end
  # ```
  macro after_run(&block)
    {%
      if block.args.size != 1
        raise <<-ERR
        The 'after_run' callback requires exactly 1 block arg to be passed.
        Example:
          after_run { |value| some_method(value) }
        ERR
      end
    %}
    def after_run(%object : T) : Nil forall T
      {% if @type.methods.map(&.name).includes?(:after_run.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {{ block.args.first }} = %object
      {{ block.body }}
    end
  end
end
