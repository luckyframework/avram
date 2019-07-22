abstract class Avram::Box
  getter operation

  SEQUENCES = {} of String => Int32

  macro inherited
    {% unless @type.abstract? %}
      {% operation = @type.name.gsub(/Box/, "::SaveOperation").id %}
      @operation : {{ operation }} = {{ operation }}.new
      setup_attribute_shortcuts({{ operation }})
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

  def self.save
    {% raise "'Box.save' has been renamed to 'Box.create' to match 'SaveOperation.create'" %}
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

  def self.create_pair
    2.times { new.create }
  end

  # Returns a value with a number to use for unique values.
  #
  # Usage:
  #
  # ```crystal
  # class UserBox < Avram::Box
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
