abstract class Avram::Factory
  getter operation

  SEQUENCES = {} of String => Int32

  macro inherited
    {% unless @type.abstract? %}
      {% model_name = @type.name.gsub(/Factory$/, "") %}
      {% operation = "#{model_name}::SaveOperation".id %}
      @operation : {{ operation }} = {{ operation }}.new

      getter before_saves : Array(-> Nil) = [] of -> Nil
      getter after_saves : Array({{ model_name.id }} -> Nil) = [] of {{ model_name.id }} -> Nil
      setup_attribute_shortcuts({{ operation }})
      setup_attributes({{ operation }})
      setup_callbacks({{ model_name }})
    {% end %}
  end

  macro setup_attribute_shortcuts(operation)
    {% for attribute in operation.resolve.constant(:COLUMN_ATTRIBUTES) %}
      def {{ attribute[:name] }}(value : {{ attribute[:type] }}{% if attribute[:nilable] %}?{% end %})
        operation.{{ attribute[:name] }}.value = value
        self
      end
    {% end %}
  end

  macro setup_attributes(operation)
    def attributes
      {
        {% for attribute in operation.resolve.constant(:COLUMN_ATTRIBUTES) %}
          {{ attribute[:name] }}: operation.{{ attribute[:name] }}.value,
        {% end %}
      }
    end
  end

  macro setup_callbacks(model_name)
    # Run `block` before the record is created
    def before_save(&block : -> Nil) : self
      @before_saves << block

      self
    end

    # Run `block` after the record is created.
    # The block will yield the created record instance
    def after_save(&block : {{ model_name.id }} -> Nil) : self
      @after_saves << block

      self
    end

    private def run_before_save_callbacks
      @before_saves.each(&.call)
    end

    private def run_after_save_callbacks(record : {{ model_name.id }})
      @after_saves.each(&.call(record))

      record
    end
  end

  def self.build_attributes(&)
    yield(new).attributes
  end

  def self.build_attributes
    new.attributes
  end

  def self.create
    new.create
  end

  def self.create(&)
    yield(new).create
  end

  def create
    run_before_save_callbacks
    record = operation.save!
    run_after_save_callbacks(record)
  end

  # Returns an array with 2 instances of the model from the Factory.
  #
  # Usage:
  #
  # ```
  # tags = TagFactory.create_pair
  # typeof(tags) # => Array(Tag)
  # tags.size    # => 2
  # ```
  def self.create_pair
    create_pair { |factory| factory }
  end

  # Similar to `create_pair`, but accepts a block which yields the factory instance.
  #
  # Both factories receive the same argument values.
  #
  # Usage:
  #
  # ```
  # TagFactory.create_pair do |factory|
  #   # set both factories name to "test"
  #   factory.name("test")
  # end
  # ```
  def self.create_pair(&)
    [1, 2].map do |n|
      self.create { |factory| yield(factory) }
    end
  end

  # Returns a value with a number to use for unique values.
  #
  # Usage:
  #
  # ```
  # class UserFactory < Avram::Factory
  #   def initialize
  #     username sequence("username")            # => username-1, username-2, etc.
  #     email "#{sequence("email")}@example.com" # => email-1@example.com, email-2@example.com, etc.
  #   end
  # end
  # ```
  def sequence(value : String) : String
    SEQUENCES[value] ||= 0
    SEQUENCES[value] += 1
    "#{value}-#{SEQUENCES[value]}"
  end
end
