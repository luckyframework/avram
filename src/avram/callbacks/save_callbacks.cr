require "./after_commit_callback"

module Avram::SaveCallbacks
  include Avram::AfterCommitCallback

  # Run the given method before saving or creating for `SaveOperation`
  #
  # This runs before saving and before the database transaction is started.
  # You can set defaults, validate, or perform any other setup necessary for
  # saving.
  #
  # Optionally you can pass an `if` or `unless` argument which allows you to
  # run this conditionally. The symbol should reference a method you've defined
  # that returns a truthy/falsey value
  #
  # ```
  # before_save :run_validations
  # before_save :validate_can_internet, unless: :too_cool_for_school?
  #
  # private def run_validations
  #   validate_required name, age
  # end
  #
  # private def validate_can_internet
  #   validate_size_of age, min: 13
  # end
  #
  # private def too_cool_for_school?
  #   [true, false].sample
  # end
  # ```
  macro before_save(method_name, if _if = nil, unless _unless = nil)
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:before_save, {{ method_name }}, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:before_save, {{ method_name }}, :unless)
    {% end %}
    before_save(if: {{ _if }}, unless: {{ _unless }}) do
      {{ method_name.id }}
    end
  end

  # Run the given block before saving or creating for `SaveOperation`
  #
  # This runs before saving and before the database transaction is started.
  # You can set defaults, validate, or perform any other setup necessary for
  # saving.
  #
  # Optionally you can pass an `if` or `unless` argument which allows you to
  # run this conditionally. The symbol should reference a method you've defined
  # that returns a truthy/falsey value
  #
  # ```
  # before_save(unless: :skip_callback?) do
  #   validate_required name, age
  # end
  #
  # private def skip_callback?
  #   false
  # end
  # ```
  macro before_save(if _if = nil, unless _unless = nil)
    {% if _if != nil && _unless != nil %}
      {% raise "Your before_save callbacks should only specify `if` or `unless`, but not both." %}
    {% end %}
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:before_save, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:before_save, :unless)
    {% end %}

    def before_save : Nil
      {% if @type.methods.map(&.name).includes?(:before_save.id) %}
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

  # Run the given method after save, but before transaction is committed
  #
  # Optionally you can pass an `if` or `unless` argument which allows you to
  # run this conditionally. The symbol should reference a method you've defined
  # that returns a truthy/falsey value
  #
  # This is a great place to do other database saves because if something goes
  # wrong the whole transaction would be rolled back.
  #
  # The newly saved record will be passed to the method.
  #
  # ```
  # class SaveComment < Comment::SaveOperation
  #   after_save touch_post
  #
  #   private def touch_post(comment : Comment)
  #     SavePost.update!(comment.post!, updated_at: Time.utc)
  #   end
  # end
  # ```
  #
  # > This is *not* a good place to do things like send messages, enqueue
  # > background jobs, or charge payments. Since the transaction could be rolled
  # > back the record may not be persisted to the database.
  # > Instead use `after_commit`
  macro after_save(method_name, if _if = nil, unless _unless = nil)
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:after_save, {{ method_name }}, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:after_save, {{ method_name }}, :unless)
    {% end %}
    after_save(if: {{ _if }}, unless: {{ _unless }}) do |object|
      {{ method_name.id }}(object)
    end
  end

  # Run the given block after save, but before transaction is committed
  #
  # Optionally you can pass an `if` or `unless` argument which allows you to
  # run this conditionally. The symbol should reference a method you've defined
  # that returns a truthy/falsey value
  #
  # This is a great place to do other database saves because if something goes
  # wrong the whole transaction would be rolled back.
  #
  # The newly saved record will be passed to the method.
  #
  # ```
  # class SaveComment < Comment::SaveOperation
  #   after_save do |comment|
  #     SavePost.update!(comment.post!, updated_at: Time.utc)
  #   end
  # end
  # ```
  #
  # > This is *not* a good place to do things like send messages, enqueue
  # > background jobs, or charge payments. Since the transaction could be rolled
  # > back the record may not be persisted to the database.
  # > Instead use `after_commit`
  macro after_save(if _if = nil, unless _unless = nil, &block)
    {% if _if != nil && _unless != nil %}
      {% raise "Your after_save callbacks should only specify `if` or `unless`, but not both." %}
    {% end %}
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:after_save, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:after_save, :unless)
    {% end %}
    {%
      if block.args.size != 1
        raise <<-ERR
        The 'after_save' callback requires exactly 1 block arg to be passed.
        Example:
          after_save do |saved_user|
            some_method(saved_user)
          end
        ERR
      end
    %}
    def after_save(%object : T) : Nil
      {% if @type.methods.map(&.name).includes?(:after_save.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {% if _if %}
      if {{ _if.id }}
        {{ block.args.first }} = %object
        {{ block.body }}
      end
      {% elsif _unless %}
      unless {{ _unless.id }}
        {{ block.args.first }} = %object
        {{ block.body }}
      end
      {% else %}
        {{ block.args.first }} = %object
        {{ block.body }}
      {% end %}
    end
  end

  # :nodoc:
  macro before(callback_method)
    {% raise <<-ERROR

      'before' is not a valid #{@type.name} callback.

      Try this...

        ▸ before_save #{callback_method.id}

      ERROR
    %}
  end

  # :nodoc:
  macro before(&block)
    {% raise <<-ERROR

      'before' is not a valid #{@type.name} callback.

      Try this...

        ▸ before_save do
          end

      ERROR
    %}
  end
end
