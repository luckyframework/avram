abstract class Avram::Box
  macro inherited
    {% raise "Avram::Box has been renamed to Avram::Factory" %}
  end
end

abstract class Avram::Factory
  getter operation

  SEQUENCES = {} of String => Int32

  macro inherited
    {% unless @type.abstract? %}
      {% operation = @type.name.gsub(/Factory$/, "::SaveOperation").id %}
      @operation : {{ operation }} = {{ operation }}.new
      setup_attribute_shortcuts({{ operation }})
      setup_attributes({{ operation }})
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

  def self.build_attributes
    yield(new).attributes
  end

  def self.build_attributes
    new.attributes
  end

  def self.create
    new.create
  end

  def self.create
    yield(new).create
  end

  def create
    operation.save!
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
  def self.create_pair
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
