require "./callback_helpers"

module Avram::AfterCommitCallback
  include Avram::CallbackHelpers

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
end
