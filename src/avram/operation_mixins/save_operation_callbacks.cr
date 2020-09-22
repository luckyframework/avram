module Avram::SaveOperationCallbacks
  macro included
    def before_save
    end

    def after_save(_record : T) forall T
    end

    def after_commit(_record : T) forall T
    end
  end

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
      {% else %}
        super
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
      {% else %}
        super
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
    def after_save(object : T)
      {% if @type.methods.map(&.name).includes?(:after_save.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {{ method_name.id }}(object)
    end
  end

  # Run the given block after save, but before transaction is committed
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
  macro after_save(&block)
    {%
      if block.args.size != 1
        raise <<-ERR
        The 'after_save' callback requires only 1 block arg to be passed.

        Example:

          after_save do |saved_user|
            some_method(saved_user)
          end
        ERR
      end
    %}
    def after_save(object : T)
      {% if @type.methods.map(&.name).includes?(:after_save.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {{ block.args.first }} = object
      {{ block.body }}
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
  macro after_commit(method_name)
    def after_commit(object : T)
      {% if @type.methods.map(&.name).includes?(:after_commit.id) %}
        previous_def
      {% else %}
        super
      {% end %}

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
  macro after_commit(&block)
    {%
      if block.args.size != 1
        raise <<-ERR
        The 'after_commit' callback requires only 1 block arg to be passed.

        Example:

          after_commit do |saved_user|
            some_method(saved_user)
          end
        ERR
      end
    %}
    def after_commit(object : T)
      {% if @type.methods.map(&.name).includes?(:after_commit.id) %}
        previous_def
      {% else %}
        super
      {% end %}

      {{ block.args.first }} = object
      {{ block.body }}
    end
  end

  # :nodoc:
  macro before(callback_method)
    {% raise <<-ERROR

      'before' is not a valid callback.

      Try this...

        ▸ before_save #{callback_method.id}

      ERROR
    %}
  end
end
