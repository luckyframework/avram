module Avram::Callbacks
  # Run the given method before saving or creating
  #
  # This runs before saving and before the database transaction is started.
  # You can set defaults, validate, or perform any other setup necessary for
  # saving.
  #
  # ```
  # before_save run_validations
  #
  # private def run_validations
  #   validate_required name, age
  # end
  # ```
  macro before_save(method_name)
    def before_save
      {% if @type.methods.map(&.name).includes?(:before_save.id) %}
        previous_def
      {% end %}

      {{ method_name.id }}
    end
  end

  # Run the given block before saving or creating
  #
  # This runs before saving and before the database transaction is started.
  # You can set defaults, validate, or perform any other setup necessary for
  # saving.
  #
  # ```
  # before_save do
  #   validate_required name, age
  # end
  # ```
  macro before_save
    def before_save
      {% if @type.methods.map(&.name).includes?(:before_save.id) %}
        previous_def
      {% end %}

      {{ yield }}
    end
  end

  # Run the given method after save, but before transaction is committed
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
  macro after_save(method_name)
    def after_save(object)
      {% if @type.methods.map(&.name).includes?(:after_save.id) %}
        previous_def
      {% end %}

      {{ method_name.id }}(object)
    end
  end

  # Run the given method after save and after successful transaction commit
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
  macro after_commit(method_name)
    def after_commit(object)
      {% if @type.methods.map(&.name).includes?(:after_commit.id) %}
        previous_def
      {% end %}

      {{ method_name.id }}(object)
    end
  end

  {% for callbacks_without_block in [:after_save, :after_commit] %}
    # :nodoc:
    macro {{ callbacks_without_block.id }}
      \{% raise <<-ERROR
        '#{callbacks_without_block.id}' does not accept a block. Instead give it a method name  to run.

        Example:

            #{callbacks_without_block.id} run_something
        ERROR
      %}
      # Will never be called but must be there so that the macro accepts a block
      \{{ yield }}
    end
  {% end %}

  {% for removed_callback in [:create, :update] %}
    # :nodoc:
    macro after_{{ removed_callback.id }}(method_name)
      \{% raise "'after_#{removed_callback}' has been removed" %}
    end

    # :nodoc:
    macro before_{{ removed_callback.id }}(method_name)
      \{% raise "'before_#{removed_callback.id}' has been removed" %}
    end
  {% end %}

  # :nodoc:
  macro before(callback_method)
    {% raise <<-ERROR

      'before' is not a valid SaveOperation callback.

      Try this...

        ▸ before_save #{ callback_method.id }

      ERROR
    %}
  end
end
