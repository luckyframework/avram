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
  #
  # `has_many` (and `has_one`) can be nested arbitrarily deep: a
  # `SaveOperation` declared as a `has_many` child may itself declare its
  # own `has_one`/`has_many` associations. Any nested value in each item's
  # hash is represented under its own key -- either JSON-encoded as a
  # plain `String` (for a JSON request) or as a set of keys prefixed with
  # `"{key}:"`/`"{key}[index]:"` (for a URL-encoded/multipart HTML form)
  # -- mirroring how a real params implementation, e.g. `Lucky::Params`,
  # represents nested values in each case, and `Avram::Params`
  # transparently decodes it again when the grandchild operation reads
  # its own params.
  #
  # ## Rendering
  #
  # Each item returned by `{name}` (e.g. `op.comments`) has its
  # `Avram::ParamKeyOverride#param_key` set to `"{name}[{index}]"` (nested
  # under whatever prefix, if any, the parent operation itself was given),
  # so the Lucky form helpers (`text_input`, etc.) render the exact
  # `name=`/`id=` that `Avram::Params`/`Lucky::Params` already knows how to
  # decode back into item `{index}`'s own hash on submission -- so this
  # "just works":
  #
  # ```
  # op.comments.each do |comment|
  #   nested_id_input(comment) # keeps updates on resubmission from creating duplicates
  #   text_input(comment.body)
  # end
  # ```
  #
  # If there are no submitted (or re-displayed) params for `{name}` *and*
  # the parent operation already has a persisted record (e.g. rendering a
  # fresh edit form), `{name}` returns one nested operation per already-
  # associated record, pre-filled from it -- mirroring what `has_one`
  # already does for its single child. This means `{name}` (e.g.
  # `op.comments`) on a persisted operation with no submitted params
  # returns the parent's existing associated records wrapped in their own
  # operations, **not** an empty `Array` as it did before this rendering
  # support existed.
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
      @_{{ name }} ||= begin
        nested_items = params.many_nested?({{ name.stringify }})

        if nested_items.empty? && !new_record?
          {{ name }}_existing_records.map_with_index do |existing_record, index|
            nested_param_key, prefix = has_many_nested_param_key({{ name.stringify }}, index)
            {{ type }}.new(existing_record, _nested_param_key: nested_param_key, _nested_param_key_prefix: prefix)
          end
        else
          results = [] of {{ type }}

          nested_items.each_with_index do |nested_params, index|
            {% if allow_destroy %}
              next if nested_marked_for_destroy?(nested_params)
            {% end %}

            nested_param_key, prefix = has_many_nested_param_key({{ name.stringify }}, index)
            existing = {{ name }}_existing_record_for(nested_params)

            nested_operation = if existing
              {{ type }}.new(existing, Avram::Params.new(nested_params), _nested_param_key: nested_param_key, _nested_param_key_prefix: prefix)
            else
              {{ type }}.new(Avram::Params.new(nested_params), _nested_param_key: nested_param_key, _nested_param_key_prefix: prefix)
            end

            results << nested_operation
          end

          results
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

  # Declares a nested `SaveOperation` for a `has_one` association.
  #
  # This lets you save/update an entire tree of records (e.g. a `Business`
  # along with its `EmailAddress`) through a single parent `SaveOperation`
  # in a type-safe way.
  #
  # ```
  # class SaveBusiness < Business::SaveOperation
  #   class SaveEmailAddress < EmailAddress::SaveOperation
  #     permit_columns address
  #   end
  #
  #   permit_columns name
  #   has_one email_address : SaveEmailAddress
  # end
  # ```
  #
  # The child operation is instantiated with the *same* params object given
  # to the parent, and reads its own attributes by its own param key (the
  # underlying model's name), so it doesn't matter what `{name}` is used
  # for the `has_one` declaration itself.
  #
  # The nested operation is always validated and saved inside the same
  # database transaction as the parent. If it fails, the entire
  # transaction -- parent included -- is rolled back and an error is added
  # to the parent under `:{name}`.
  #
  # `has_one` (and `has_many`) can be nested arbitrarily deep: a
  # `SaveOperation` declared as a `has_one` child may itself declare its
  # own `has_one`/`has_many` associations.
  #
  # ## Rendering
  #
  # `{name}` (e.g. `op.email_address`) has its
  # `Avram::ParamKeyOverride#param_key` set so the Lucky form helpers
  # (`text_input`, etc.) render the exact `name=`/`id=` that
  # `Avram::Params`/`Lucky::Params` already knows how to decode back on
  # submission, at any nesting depth -- so this "just works":
  #
  # ```
  # text_input(op.email_address.address)
  # ```
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
      @_{{ name }} ||= begin
        nested_param_key, prefix = has_one_nested_param_key({{ type }}.param_key)

        if new_record?
          {{ type }}.new(params, _nested_param_key: nested_param_key, _nested_param_key_prefix: prefix)
        else
          {{ type }}.new(record.not_nil!.{{ assoc[:assoc_name].id }}!, params, _nested_param_key: nested_param_key, _nested_param_key_prefix: prefix)
        end
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

  # :nodoc:
  #
  # Computes the fully-qualified key a `has_one` nested child operation's
  # own attributes should be rendered/extracted under (see
  # `Avram::ParamKeyOverride#param_key`), along with the prefix any of the
  # child's own nested (`has_one`/`has_many`) operations should build
  # their own key on top of. Must be computed *before* the child operation
  # is constructed (see `Avram::ParamKeyOverride#apply_nested_param_key_override`)
  # and passed in via the `_nested_param_key`/`_nested_param_key_prefix`
  # constructor arguments.
  #
  # Passing through a `has_one` boundary carries the inherited prefix
  # through *unchanged*, only combining it with the child's own
  # (model-derived) `child_param_key` to build the child's own key when a
  # prefix is actually present -- this mirrors how `has_one` already
  # shares the exact same `Avram::Paramable` with its child (see
  # `#has_one` above), rather than wrapping it under its own key.
  private def has_one_nested_param_key(child_param_key : String) : Tuple(String, String)
    prefix = nested_param_key_prefix
    key = prefix.presence ? "#{prefix}:#{child_param_key}" : child_param_key
    {key, prefix}
  end

  # :nodoc:
  #
  # Computes the fully-qualified key a `has_many` nested child operation
  # (at position `index` within its own array) own attributes should be
  # rendered/extracted under (see `Avram::ParamKeyOverride#param_key`),
  # along with the prefix any of the child's own nested (`has_one`/
  # `has_many`) operations should build their own key on top of. Must be
  # computed *before* the child operation is constructed (see
  # `Avram::ParamKeyOverride#apply_nested_param_key_override`) and passed
  # in via the `_nested_param_key`/`_nested_param_key_prefix` constructor
  # arguments.
  #
  # Passing through a `has_many` boundary appends `"{association
  # name}[{index}]"` to whatever prefix was inherited, and that combined
  # value becomes both the child's own key and the prefix its own nested
  # operations build on -- this mirrors the `"{key}[index]:"` convention
  # `Avram::Params#many_nested` already parses (see `#has_many` above).
  private def has_many_nested_param_key(association_name : String, index : Int32) : Tuple(String, String)
    prefix = nested_param_key_prefix
    key = prefix.presence ? "#{prefix}:#{association_name}[#{index}]" : "#{association_name}[#{index}]"
    {key, key}
  end
end
