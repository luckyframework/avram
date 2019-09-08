require "dexter"
require "lucky_cli"
require "wordsmith"
require "habitat"
require "./avram/criteria"
require "./avram/type"
require "./avram/table_for"
require "./avram/between_criteria"
require "./avram/charms/**"
require "./avram/migrator/**"
require "./avram/tasks/**"
require "./avram/**"
require "db"
require "pg"
require "./avram/pool_statement_logging"
require "uuid"

module Avram
  Habitat.create do
    setting lazy_load_enabled : Bool = true
    setting logger : Dexter::Logger = Dexter::Logger.new(nil)
    setting query_log_level : ::Logger::Severity?
    setting save_failed_log_level : ::Logger::Severity? = ::Logger::Severity::WARN
    setting database_to_migrate : Avram::Database.class, example: "AppDatabase"
    setting time_formats : Array(String) = [] of String
  end

  def self.logger
    settings.logger
  end
end
