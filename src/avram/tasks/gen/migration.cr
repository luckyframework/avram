require "colorize"
require "ecr"
require "file_utils"

class Avram::Migrator::MigrationGenerator
  include LuckyTask::TextHelpers

  getter :name
  @_version : String?
  @name : String
  @migrate_contents : String?
  @rollback_contents : String?

  ECR.def_to_s "#{__DIR__}/migration.ecr"

  def initialize(@name)
  end

  def initialize(@name, @migrate_contents : String, @rollback_contents : String)
  end

  def generate(@_version = @_version)
    ensure_camelcase_name
    make_migrations_folder_if_missing
    ensure_unique
    File.write(file_path, contents)
    io.puts "Created #{migration_class_name.colorize(:green)} in .#{relative_file_path.colorize(:green)}"
  end

  private def io
    Gen::Migration.settings.io
  end

  def formatted_migrate_contents : String?
    @migrate_contents.try do |contents|
      pad_contents(contents)
    end
  end

  def formatted_rollback_contents : String?
    @rollback_contents.try do |contents|
      pad_contents(contents)
    end
  end

  private def pad_contents(contents : String) : String
    String.build do |string|
      contents.split("\n").each_with_index do |line, index|
        if index.zero?
          string << line
        else
          string << "    "
          string << line
        end
        string << "\n"
      end
    end.chomp
  end

  private def ensure_camelcase_name
    if name.camelcase != name
      raise <<-ERROR
      Migration must be in camel case.

        #{green_arrow} Try this instead: #{"lucky gen.migration #{name.camelcase}".colorize(:green)}
      ERROR
    end
  end

  private def ensure_unique
    d = Dir.new(Dir.current + "/db/migrations")
    d.each_child { |x|
      if x.starts_with?(/[0-9]{14}_#{name.underscore}.cr/)
        raise <<-ERROR
          Migration name must be unique

          Migration name: #{name.underscore}.cr already exists as: #{x}.
        ERROR
      end
    }
  end

  private def migration_class_name
    "#{name}::V#{version}"
  end

  private def make_migrations_folder_if_missing
    FileUtils.mkdir_p Dir.current + "/db/migrations"
  end

  private def file_path
    Dir.current + relative_file_path
  end

  private def relative_file_path
    "/db/migrations/#{version}_#{name.underscore}.cr"
  end

  private def version
    @_version ||= Time.utc.to_s("%Y%m%d%H%M%S")
  end

  private def contents
    to_s
  end
end

class Gen::Migration < LuckyTask::Task
  summary "Generate a new migration"

  Habitat.create do
    setting io : IO = STDOUT
  end

  def help_message
    <<-TEXT
    Generate a new migration using the passed in migration name.

    The migration name must be CamelCase. No other options are available.

    Examples:

      lucky gen.migration CreateUsers
      lucky gen.migration AddAgeToUsers
      lucky gen.migration MakeUserNameOptional

    TEXT
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
