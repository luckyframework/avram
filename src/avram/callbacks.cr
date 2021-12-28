module Avram::Callbacks
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

  # Same as `before_save`, but with a different name
  macro before_delete(method_name, if _if = nil, unless _unless = nil)
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:before_delete, {{ method_name }}, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:before_delete, {{ method_name }}, :unless)
    {% end %}
    before_delete(if: {{ _if }}, unless: {{ _unless }}) do
      {{ method_name.id }}
    end
  end

  # Run the given method before `run` is called on an `Operation`.
  #
  # ```
  # before_run :validate_inputs
  #
  # private def validate_inputs
  #   validate_required data
  # end
  # ```
  macro before_run(method_name)
    before_run do
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

    def before_save
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

  macro before_delete(if _if = nil, unless _unless = nil)
    {% if _if != nil && _unless != nil %}
      {% raise "Your before_delete callbacks should only specify `if` or `unless`, but not both." %}
    {% end %}
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:before_delete, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:before_delete, :unless)
    {% end %}

    def before_delete
      {% if @type.methods.map(&.name).includes?(:before_delete.id) %}
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

  # Run the given block before `run` is called on an `Operation`.
  #
  # ```
  # before_run do
  #   validate_required data
  # end
  # ```
  macro before_run
    def before_run
      {% if @type.methods.map(&.name).includes?(:before_run.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {{ yield }}
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

  # Same as `after_save` but with a different name
  macro after_delete(method_name, if _if = nil, unless _unless = nil)
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:after_delete, {{ method_name }}, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:after_delete, {{ method_name }}, :unless)
    {% end %}
    after_delete(if: {{ _if }}, unless: {{ _unless }}) do |object|
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
    def after_save(%object : T)
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

  macro after_delete(if _if = nil, unless _unless = nil, &block)
    {% if _if != nil && _unless != nil %}
      {% raise "Your after_delete callbacks should only specify `if` or `unless`, but not both." %}
    {% end %}
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:after_delete, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:after_delete, :unless)
    {% end %}
    {%
      if block.args.size != 1
        raise <<-ERR
        The 'after_delete' callback requires exactly 1 block arg to be passed.
        Example:
          after_delete do |deleted_user|
            some_method(deleted_user)
          end
        ERR
      end
    %}
    def after_delete(%object : T)
      {% if @type.methods.map(&.name).includes?(:after_delete.id) %}
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
    def after_run(%object)
      {% if @type.methods.map(&.name).includes?(:after_run.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {{ block.args.first }} = %object
      {{ block.body }}
    end
  end

  # Run the given method after save and after successful transaction commit
  #
  # Optionally you can pass an `if` or `unless` argument which allows you to
  # run this conditionally. The symbol should reference a method you've defined
  # that returns a truthy/falsey value
  #
  # The newly saved record will be passed to the method.
  #
  # ```
  # class SaveComment < Comment::SaveOperation
  #   after_commit notify_post_author
  #
  #   private def notify_post_author(comment : Comment)
  #     NewCommentNotificationEmail.new(comment, to: comment.author!).deliver_now
  #   end
  # end
  # ```
  #
  macro after_commit(method_name, if _if = nil, unless _unless = nil)
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:after_commit, {{ method_name }}, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_inline_callbacks(:after_commit, {{ method_name }}, :unless)
    {% end %}
    after_commit(if: {{ _if }}, unless: {{ _unless }}) do |object|
      {{ method_name.id }}(object)
    end
  end

  # Run the given block after save and after successful transaction commit
  #
  # The newly saved record will be passed to the method.
  #
  # ```
  # class SaveComment < Comment::SaveOperation
  #   after_commit do |comment|
  #     NewCommentNotificationEmail.new(comment, to: comment.author!).deliver_now
  #   end
  # end
  # ```
  macro after_commit(if _if = nil, unless _unless = nil, &block)
    {% if _if != nil && _unless != nil %}
      {% raise "Your after_commit callbacks should only specify `if` or `unless`, but not both." %}
    {% end %}
    {% unless _if.is_a?(SymbolLiteral) || _if.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:after_commit, :if)
    {% end %}
    {% unless _unless.is_a?(SymbolLiteral) || _unless.is_a?(NilLiteral) %}
      conditional_error_for_block_callbacks(:after_commit, :unless)
    {% end %}
    {%
      if block.args.size != 1
        raise <<-ERR
        The 'after_commit' callback requires exactly 1 block arg to be passed.
        Example:
          after_commit do |saved_user|
            some_method(saved_user)
          end
        ERR
      end
    %}
    def after_commit(%object : T)
      {% if @type.methods.map(&.name).includes?(:after_commit.id) %}
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
