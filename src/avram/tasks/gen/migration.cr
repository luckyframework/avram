require "./migration_generator"

class Gen::Migration < LuckyTask::Task
  summary "Generate a new migration"
  help_message <<-TEXT
  Generate a new migration using the passed in migration name.

  The migration name must be CamelCase. No other options are available.

  Examples:

    lucky gen.migration CreateUsers
    lucky gen.migration AddAgeToUsers
    lucky gen.migration MakeUserNameOptional

  TEXT

  positional_arg :migration_name, "The migration class name", format: /^[A-Z]/

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
      Avram::Migrator::MigrationGenerator.new(name: migration_name, io: output).generate
    end
  end
end
