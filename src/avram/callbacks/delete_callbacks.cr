require "./after_commit_callback"

module Avram::DeleteCallbacks
  include Avram::AfterCommitCallback

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
end
