require "./migration_generator"

class Gen::Migration < LuckyTask::Task
  summary "Generate a new migration"
  help_message <<-TEXT
  Generate a new migration using the passed in migration file name.

  The migration file name can be underscore or CamelCase. No other options are available.

  Examples:

    lucky gen.migration create_users
    lucky gen.migration AddAgeToUsers

  TEXT

  positional_arg :migration_file_name, "The migration file name"

  Habitat.create do
    setting io : IO = STDOUT
  end

  def self.silence_output(&)
    temp_config(io: IO::Memory.new) do
      yield
    end
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::MigrationGenerator.new(name: migration_file_name, io: output).generate
    end
  end
end
