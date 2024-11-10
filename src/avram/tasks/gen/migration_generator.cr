require "ecr"
require "file_utils"

class Avram::Migrator::MigrationGenerator
  include LuckyTask::TextHelpers

  getter name : String, io : IO
  @_version : String?
  @migrate_contents : String?
  @rollback_contents : String?

  ECR.def_to_s "#{__DIR__}/migration.ecr"

  def initialize(@name : String, @io : IO)
  end

  def initialize(@name : String, @io : IO, @migrate_contents : String, @rollback_contents : String)
  end

  def generate(@_version = @_version)
    @name = name.camelcase
    make_migrations_folder_if_missing
    ensure_unique
    File.write(file_path, contents)
    io.puts "Created #{migration_class_name.colorize(:green)} in .#{relative_file_path.colorize(:green)}"
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
      contents.split(EOL).each_with_index do |line, index|
        if index.zero?
          string << line
        else
          string << "    "
          string << line
        end
        string << EOL
      end
    end.chomp
  end

  private def ensure_unique
    d = Dir.new(Dir.current + Path["/db/migrations"].to_s)
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
    FileUtils.mkdir_p Dir.current + Path["/db/migrations"].to_s
  end

  private def file_path
    Dir.current + relative_file_path
  end

  private def relative_file_path
    Path["/db/migrations/#{version}_#{name.underscore}.cr"].to_s
  end

  private def version
    @_version ||= Time.utc.to_s("%Y%m%d%H%M%S")
  end

  private def contents
    to_s
  end
end
