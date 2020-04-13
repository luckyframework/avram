require "dexter"
require "lucky_cli"
require "wordsmith"
require "habitat"
require "blank"
require "./avram/object_extensions"
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
    setting database_to_migrate : Avram::Database.class, example: "AppDatabase"
    setting time_formats : Array(String) = [] of String
  end

  Log            = ::Log.for(Avram)
  QueryLog       = Log.for("query")
  FailedQueryLog = Log.for("failed_query")
  SaveFailedLog  = Log.for("save_failed")
end
