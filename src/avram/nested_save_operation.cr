module Avram::NestedSaveOperation
  macro included
    macro inherited
      define_has_one
    end
  end

  macro define_has_one
    macro has_one(type_declaration)
      \{% name = type_declaration.var %}
      \{% type = type_declaration.type.resolve %}

      \{% model_type = type.ancestors.find do |t|
          t.stringify.starts_with?("Avram::SaveOperation(")
        end.type_vars.first %}

      \{% assoc = T.constant(:ASSOCIATIONS).find do |assoc|
          assoc[:relationship_type] == :has_one &&
            assoc[:type].resolve.name == model_type.name
        end %}

      \{% if ! assoc %}
        \{% raise "#{T} must have a has_one association with #{model_type}" %}
      \{% end %}

      \{% for need in type.constant(:OPERATION_NEEDS) %}
        needs \{{ name }}_\{{ need }}
      \{% end %}

      after_save save_\{{ name }}

      def save_\{{ name }}(saved_record)
        unless \{{ name }}.save
          add_error(:\{{ name }}, "failed")
          mark_nested_save_operations_as_failed
          database.rollback
        end
      end

      def \{{ name }}
        @\{{ name }} ||= if new_record?
          \{% begin %}\{{ type }}.new(
            params,
            \{% for need in type.constant(:OPERATION_NEEDS) %}
              \{{ need.var }}: \{{ name }}_\{{ need.var }},
            \{% end %}
          )\{% end %}
        else
          \{% begin %}\{{ type }}.new(
            record.not_nil!.\{{ assoc[:assoc_name].id }}!,
            params,
            \{% for need in type.constant(:OPERATION_NEEDS) %}
              \{{ need.var }}: \{{ name }}_\{{ need.var }},
            \{% end %}
          )\{% end %}
        end

        nested = @\{{ name }}.not_nil!

        record.try do |record|
          nested.\{{ @type.constant(:FOREIGN_KEY).id }}.value = record.id
        end

        nested
      end

      def nested_save_operations
        \{% if @type.methods.map(&.name).includes?(:nested_save_operations.id) %}
          previous_def +
        \{% end %}
        [\{{ name }}]
      end
    end

    macro inherited
      define_has_one
    end
  end

  def mark_nested_save_operations_as_failed
    nested_save_operations.each do |operation|
      operation.as(Avram::MarkAsFailed).mark_as_failed
    end
  end

  def nested_save_operations
    [] of Avram::MarkAsFailed
  end
end
