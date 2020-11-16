class Avram::Repo
  forward_missing_to class_has_been_renamed

  # :nodoc:
  def self.configure(*args, **named_args, &block)
    class_has_been_renamed_helpful_error
  end

  macro class_has_been_renamed_helpful_error
    {% raise <<-ERROR
      Avram::Repo has been renamed to Avram::Database and requires a subclass now.

      Try this...

        1. Create a database class called 'AppDatabase' that inherits from 'Avram::Database'
        2. Configure it with 'AppDatabase.configure'
        3. Set the database in 'BaseModel' (can also be specific per model). Example:

            class BaseModel < Avram::Model
              def self.database
                AppDatabase
              end
            end

      ERROR
    %}
  end
end
