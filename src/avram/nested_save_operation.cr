module Avram::NestedSaveOperation
  # Declares a nested `SaveOperation` for a `has_many` association.
  #
  # This lets you save/update/destroy an entire tree of records (e.g. a
  # `Post` along with all of its `Comment`s) through a single parent
  # `SaveOperation` in a type-safe way, similar to Rails'
  # `accepts_nested_attributes_for`.
  #
  # ```
  # class SavePost < Post::SaveOperation
  #   class SaveComment < Comment::SaveOperation
  #     permit_columns body
  #   end
  #
  #   permit_columns title
  #   has_many comments : SaveComment
  # end
  # ```
  #
  # Params are read from `params.many_nested?("comments")`, so a form (or
  # JSON payload) should submit an array of hashes under the `comments` key.
  # Each hash may include an `id` key to update an existing associated
  # record; otherwise a new record is created.
  #
  # All nested operations are validated and saved (or, when `allow_destroy`
  # is `true` and a hash includes a truthy `_destroy` key, deleted) inside
  # the same database transaction as the parent. If any nested operation
  # fails, the entire transaction -- parent included -- is rolled back and
  # an error is added to the parent under `:{name}`.
  macro has_many(type_declaration, allow_destroy = false)
    {% name = type_declaration.var %}
    {% type = type_declaration.type.resolve %}

    {% model_type = type.ancestors.find do |ancestor|
         ancestor.stringify.starts_with?("Avram::SaveOperation(")
       end.type_vars.first %}

    {% assoc = T.constant(:ASSOCIATIONS).find do |assoc|
         assoc[:relationship_type] == :has_many &&
           assoc[:type].resolve.name == model_type.name
       end %}

    {% unless assoc %}
      {% type_declaration.raise "#{T} must have a has_many association with #{model_type}" %}
    {% end %}

    @_{{ name }} : Array({{ type }})?
    @_{{ name }}_existing_records : Array({{ model_type }})?
    {% if allow_destroy %}
      @_{{ name }}_to_delete : Array({{ model_type }}::DeleteOperation)?
    {% end %}

    after_save save_{{ name }}

    def save_{{ name }}(saved_record)
      {{ name }}.each do |nested_operation|
        nested_operation.{{ assoc[:foreign_key].id }}.value = saved_record.id

        unless nested_operation.save
          add_error(:{{ name }}, "failed")
          mark_nested_save_operations_as_failed
          write_database.rollback
        end
      end

      {% if allow_destroy %}
        {{ name }}_to_delete.each do |nested_delete_operation|
          unless nested_delete_operation.delete
            add_error(:{{ name }}, "failed to delete")
            mark_nested_save_operations_as_failed
            write_database.rollback
          end
        end
      {% end %}
    end

    def {{ name }} : Array({{ type }})
      @_{{ name }} ||= params.many_nested?({{ name.stringify }}).compact_map do |nested_params|
        {% if allow_destroy %}
          next nil if nested_marked_for_destroy?(nested_params)
        {% end %}

        existing = {{ name }}_existing_record_for(nested_params)

        if existing
          {{ type }}.new(existing, Avram::Params.new(nested_params))
        else
          {{ type }}.new(Avram::Params.new(nested_params))
        end
      end
    end

    {% if allow_destroy %}
      def {{ name }}_to_delete : Array({{ model_type }}::DeleteOperation)
        @_{{ name }}_to_delete ||= params.many_nested?({{ name.stringify }}).compact_map do |nested_params|
          next nil unless nested_marked_for_destroy?(nested_params)

          {{ name }}_existing_record_for(nested_params).try do |existing|
            {{ model_type }}::DeleteOperation.new(existing)
          end
        end
      end
    {% end %}

    private def {{ name }}_existing_record_for(nested_params : Hash(String, String)) : {{ model_type }}?
      id = nested_params["id"]?
      return if id.nil?

      {{ name }}_existing_records.find { |existing_record| existing_record.id.to_s == id }
    end

    private def {{ name }}_existing_records : Array({{ model_type }})
      @_{{ name }}_existing_records ||= if new_record?
        [] of {{ model_type }}
      else
        record.not_nil!.{{ assoc[:assoc_name].id }}!
      end
    end

    def nested_save_operations
      {% if @type.methods.map(&.name).includes?(:nested_save_operations.id) %}
        previous_def +
      {% end %}
      {{ name }}{% if allow_destroy %} + {{ name }}_to_delete{% end %}
    end
  end

  macro has_one(type_declaration)
    {% name = type_declaration.var %}
    {% type = type_declaration.type.resolve %}

    {% model_type = type.ancestors.find do |ancestor|
         ancestor.stringify.starts_with?("Avram::SaveOperation(")
       end.type_vars.first %}

    {% assoc = T.constant(:ASSOCIATIONS).find do |assoc|
         assoc[:relationship_type] == :has_one &&
           assoc[:type].resolve.name == model_type.name
       end %}

    {% unless assoc %}
      {% type_declaration.raise "#{T} must have a has_one association with #{model_type}" %}
    {% end %}

    @_{{ name }} : {{ type }} | Nil

    after_save save_{{ name }}

    def save_{{ name }}(saved_record)
      {{ name }}.{{ @type.constant(:FOREIGN_KEY).id }}.value = saved_record.id

      unless {{ name }}.save
        add_error(:{{ name }}, "failed")
        mark_nested_save_operations_as_failed
        write_database.rollback
      end
    end

    def {{ name }}
      @_{{ name }} ||= if new_record?
        {{ type }}.new(params)
      else
        {{ type }}.new(record.not_nil!.{{ assoc[:assoc_name].id }}!, params)
      end
    end

    def nested_save_operations
      {% if @type.methods.map(&.name).includes?(:nested_save_operations.id) %}
        previous_def +
      {% end %}
      [{{ name }}]
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

  # :nodoc:
  #
  # Returns `true` if the given nested params hash is marked for
  # destruction via a truthy `_destroy` key (e.g. `"true"` or `"1"`).
  #
  # Used by `has_many` when `allow_destroy: true` is set.
  private def nested_marked_for_destroy?(nested_params : Hash(String, String)) : Bool
    value = nested_params["_destroy"]?
    !value.nil? && %w[true 1].includes?(value)
  end
end
