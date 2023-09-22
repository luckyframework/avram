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

  Habitat.create do
    setting io : IO = STDOUT
  end

  def self.silence_output(&)
    temp_config(io: IO::Memory.new) do
      yield
    end
  end

  def call(name : String? = nil)
    Avram::Migrator.run do
      name = name || ARGV.first?
      if name
        Avram::Migrator::MigrationGenerator.new(name: name).generate
      else
        raise "Migration name is required. Example: lucky gen.migration CreateUsers".colorize(:red).to_s
      end
    end
  end
end
