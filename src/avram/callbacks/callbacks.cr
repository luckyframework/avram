module Avram::Callbacks
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
end
